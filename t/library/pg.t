#!./parrot 
# Copyright (C) 2006, The Perl Foundation.
# $Id$

=head1 NAME

t/library/pg.t  -- Postgres Tests

=head1 SYNOPSIS

  ./parrot t/library/pg.t

=head1 DESCRIPTION

Test Parrot's libpg interface. The test is using the user's default
table, which should be created by your sysadmin.

=cut

.const int N_TESTS = 7

.sub main :main
    load_bytecode 'Test/Builder.pir'
    .local pmc test       
    test = new 'Test::Builder'
    push_eh no_pg
    load_bytecode 'postgres.pir'
    test.'plan'(N_TESTS)
    test.'ok'(1, 'load_bytecode')
    load_bytecode 'Pg.pir'
    test.'ok'(1, 'load_bytecode Pg')
    .local pmc cl, con, res
    cl = getclass 'Pg'
    test.'ok'(1, 'Pg class exists')
    con = cl.'connectdb'('')           # assume table = user is present
    $I0 = isa con, ['Pg'; 'Conn']
    test.'ok'($I0, 'con isa Pg;Conn')
    $I0 = istrue con
    test.'ok'($I0, 'con is true after connect')
# TODO
    con.'finish'()
    test.'ok'(1, 'con.finish()')
    $I0 = isfalse con
    test.'ok'($I0, 'con is false after finish')
    test.'finish'()
    end
no_pg:	
    .local pmc ex, msg
    .get_results(ex, msg)
    test.'BAILOUT'(msg)
    test.'finish'()
.end

