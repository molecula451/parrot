#! /usr/bin/perl -w
#
# ops2c.pl
#
# Generate a C source file from the methods defined in a .pmc file.
#

use FindBin;
use lib 'lib';
use lib "$FindBin::Bin/..";
use lib "$FindBin::Bin/../lib";
use Parrot::Vtable;
use strict;

my %default = parse_vtable("$FindBin::Bin/../vtable.tbl");
my $signature_re = qr{
    ^
    (?:             #blank spaces and comments
      [\n\s]*
      (?:/\*.*?\*/)?  # C-like comments
    )*
  
    (\w+\**)      #type
    \s+
    (\w+)         #method name
    \s*    
    \(([^\(]*)\)  #parameters
}sx;

sub extract_balanced {
    my $balance = 0;
    my $lines = 0;
    for(shift) {
        s/^(\s+)//;
        $lines += count_newlines($1);
        /^\{/ or die "bad block open: ".substr($_,0,10),"..."; # }
        while(/(\{)|(\})/g) {
            if($1) {
                $balance++;
            } else { # $2
                --$balance or return (substr($_, 0, pos, ""),  $_, $lines);
            }
        }
        die "Badly balanced" if $balance;
    }
}

sub parse_superpmc {
  local $_ = shift;

  my ($classname) = s/(?:.*?)^\s*pmclass ([\w]*)//ms;

  my $superpmc = 'default';
  my $saw_extends;
  while (s/^(\s*)(\w+)//s) {
      if ($saw_extends) {
          $superpmc = $2;
          last;
      } elsif ($2 eq 'extends') {
          $saw_extends = 1;
      }
  }

  my ($classblock) = extract_balanced($_);
  $classblock = substr($classblock, 1,-1); # trim out the { }

  my @methods;

  while ($classblock =~ s/($signature_re)//) {
     my $methodname = $3;
     next if ($classblock =~ s/^(\s*=\s*default;?\s*)//s);
     push @methods, $methodname;
     (undef, $classblock) = extract_balanced($classblock);
  }

  return \@methods, $superpmc;
}

sub superpmc_info {
    my $pmc = shift;
    my $filename = "$FindBin::Bin/\L$pmc\E.pmc";
    print "Scanning $filename...\n";
    local $/;
    open(SUPERPMC, $filename) or die "open superpmc file $filename: $!";
    my $data = <SUPERPMC>;
    close SUPERPMC;
    return parse_superpmc($data);
}

sub scan_inheritance_tree {
    my ($class) = @_;

    my %methods; # { methodname => class }
    while ($class ne 'default') {
        my ($methods, $super) = superpmc_info($class);
        foreach my $method (@$methods) {
            $methods{$method} ||= $class;
        }
        $class = $super;
    }

    foreach my $method (@{ $default{order} }) {
        $methods{$method} ||= 'default';
    }

    return \%methods;
}

sub Usage {
    print STDERR <<_EOF_;
usage: $0 class.pmc [--no-lines] [class2.pmc ...]
  --no-lines suppresses #line directives
_EOF_
    exit 1;
}

#
# Process command-line arguments:
#

my $suppress_lines;
Usage() unless @ARGV;
if ($ARGV[0] eq '--no-lines') {
    $suppress_lines = 1;
    shift(@ARGV);
}

while (my $file = shift @ARGV) {

  my $base = $file;
  $base =~ s/\.pmc$//;  
  my $cfile = "$base.c";
  my $hfile = "$base.h";

  die "$0: Could not read class file '$file'!\n" unless -e $file; 
  
  open (PMC, $file) || die "$0: Unable to open file '$file'\n";  
  my @contents = <PMC>;
  my $contents = join('', @contents);
  close PMC;
      
  my ($coutput, $houtput) = filter($contents, $file, $cfile); # run the filter

  open (SOURCE, ">$cfile") || die "$0: Could not write file '$cfile'\n";
  print SOURCE $coutput;  
  close SOURCE;

  open (SOURCE, ">$hfile") || die "$0: Could not write file '$hfile'\n";
  print SOURCE $houtput;
  close SOURCE;
}

my %flags;

sub count_newlines {
    return scalar(() = $_[0] =~ /\n/g);
}

sub filter {
  my ($contents, $pmcfile, $cfile) = @_;
  my $lineno = 1;
    
  $contents =~ s/^(.*?^\s*)pmclass ([\w]*)//ms; 
  my ($pre, $classname) = ($1, $2);
  $lineno += count_newlines($1);

  my $methodloc = scan_inheritance_tree($classname);

  my $saw_extends;
  my $superpmc = 'default';
  while ($contents =~ s/^(\s*)(\w+)//s) {
      $lineno += count_newlines($1);
      if ($saw_extends) {
          $superpmc = $2;
          $saw_extends = 0;
      } elsif ($2 eq 'extends') {
          $saw_extends = 1;
      } else {
          $flags{$2}++;
      }
  }

  my ($classblock, $post, $lines) = extract_balanced($contents);
  $lineno += $lines;
  $classblock = substr($classblock, 1,-1); # trim out the { }

  my @methods;

  my $OUT = '';
  my $HOUT = <<"EOC";
 /* Do not edit - automatically generated from '$pmcfile' by $0 */

EOC
  my %defaulted;

  while ($classblock =~ s/($signature_re)//) {
     $lineno += count_newlines($1);
     my ($type, $methodname, $parameters) = ($2,$3,$4);

     $parameters = ", $parameters" if $parameters =~ /\w/;
     if ($classblock =~ s/^(\s*=\s*default;?\s*)//s) {
        $lineno += count_newlines($1);
        $defaulted{$methodname}++;
        push @methods, $methodname;
        next;
     }

     my ($methodblock, $rema, $lines) = extract_balanced($classblock);
     $lineno += $lines;
  
     $methodblock =~ s/SELF/pmc/g;
     $methodblock =~ s/INTERP/interpreter/g;
    
     my $decl = "$type Parrot_${classname}_${methodname} (struct Parrot_Interp *interpreter, PMC* pmc$parameters)";
     $OUT .= $decl;
     $HOUT .= "extern $decl;\n";
     $OUT .= "\n#line $lineno \"$pmcfile\"\n   " unless $suppress_lines;
     $OUT .= $methodblock;
     $OUT .= "\n\n";

     $lineno += count_newlines($methodblock);
     $classblock = $rema;
     push @methods, $methodname;
  };

  @methods = map { "Parrot_$methodloc->{$_}_$_" } @{ $default{order} };

  my $methodlist = join (",\n        ", @methods);
  my $initname = "Parrot_$classname" . "_class_init";

  my %visible_supers;
  @visible_supers{values %$methodloc} = ();

  my $includes = '';
  foreach my $class (keys %visible_supers) {
      # No, include yourself to check your headers match your bodies
      # (and gcc -W... is happy then)
      # next if $class eq $classname;
      $includes .= qq(#include "\L$class.h"\n);
  }


  $OUT = <<EOC . $OUT;
 /* Do not edit - automatically generated from '$pmcfile' by $0 */
$pre
${includes}
static STRING* whoami;

EOC

  unless (exists $flags{noinit}) {
      my $initline = 1+count_newlines($OUT)+1;
      $OUT .= qq(#line $initline "$cfile"\n) unless $suppress_lines;
      $HOUT .= <<EOH;
void $initname (INTVAL);
EOH
      $OUT .= <<EOC;

void $initname (INTVAL entry) {

    struct _vtable temp_base_vtable = {
        NULL,
        enum_class_$classname,
        0, /* int_type - change me */
        0, /* float_type - change me */
        0, /* num_type - change me */
        0, /* string_type - change me */
        $methodlist
        };
    
   whoami = string_make(NULL, /* DIRTY HACK */
       "$classname", 7, 0, 0, 0);

   Parrot_base_vtables[entry] = temp_base_vtable;
}
EOC
  }

  return ($OUT, $HOUT);
}
