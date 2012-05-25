/*
Copyright (C) 2001-2010, Parrot Foundation.

=head1 NAME

src/io/stringhandle.c - StringHandle vtables and helper routines

=head1 DESCRIPTION


=cut

*/

#include "parrot/parrot.h"
#include "io_private.h"
#include "pmc/pmc_stringhandle.h"

/* HEADERIZER HFILE: src/io/io_private.h */

io_stringhandle_setup_vtable(PARROT_INTERP, IO_VTABLE *vtable)
{
    ASSERT_ARGS(io_stringhandle_setup_vtable)
    vtable->name = "StringHandle";
    vtable->read_s = io_stringhandle_read_s;
    vtable->read_b = io_stringhandle_read_b;
    vtable->write_s = io_stringhandle_write_s;
    vtable->readline_s = io_stringhandle_readline_s;
    vtable->readall_s = io_stringhandle_readall_s;
    vtable->flush = io_stringhandle_flush;
    vtable->is_eof = io_stringhandle_is_eof;
    vtable->tell = io_stringhandle_tell;
    vtable->peek_b = io_stringhandle_peek_b;
    vtable->seek = io_stringhandle_seek;
    vtable->open = io_stringhandle_open;
    vtable->is_open = io_stringhandle_is_open;
    vtable->close = io_stringhandle_close;
}


static STRING *
io_stringhandle_read_s(PARROT_INTERP, ARGMOD(PMC *handle), size_t char_length)
{
    ASSERT_ARGS(io_stringhandle_read_s)
}

static INTVAL
io_stringhandle_read_b(PARROT_INTERP, ARGMOD(PMC *handle), ARGOUT(char *buffer), size_t byte_length)
{
    ASSERT_ARGS(io_stringhandle_read_b)
}

static INTVAL
io_stringhandle_write_s(PARROT_INTERP, ARGMOD(PMC *handle), ARGIN(STRING *s), size_t char_length)
{
    ASSERT_ARGS(io_stringhandle_write_s)
}

static INTVAL
io_stringhandle_write_b(PARROT_INTERP, ARGMOD(PMC *handle), ARGIN(char *buffer), size_t byte_length)
{
    ASSERT_ARGS(io_stringhandle_write_b)
}

static STRING *
io_stringhandle_readline_s(PARROT_INTERP, ARGMOD(PMC *handle), INTVAL terminator)
{
    ASSERT_ARGS(io_stringhandle_readline_s)
    INTVAL offset, newline_pos, read_length, orig_length;

    orig_length = Parrot_str_byte_length(interp, result);
    GETATTR_StringHandle_read_offset(interp, pmc, offset);
    newline_pos = STRING_index(interp, result, CONST_STRING(interp, "\n"), offset);

    /* No newline found, read the rest of the string. */
    if (newline_pos == -1)
        read_length = orig_length - offset;
    else
        read_length = newline_pos - offset + 1; /* +1 to include the newline */

    result = STRING_substr(interp, result, offset, read_length);
    SETATTR_StringHandle_read_offset(interp, pmc, newline_pos + 1);

}

static STRING *
io_stringhandle_readall_s(PARROT_INTERP, ARGMOD(PMC *handle))
{
    ASSERT_ARGS(io_stringhandle_readall_s)
}

static INTVAL
io_stringhandle_flush(PARROT_INTERP, ARGMOD(PMC *handle))
{
    ASSERT_ARGS(io_stringhandle_flush_s)
}

static INTVAL
io_stringhandle_is_eof(PARROT_INTERP, ARGMOD(PMC *handle))
{
    ASSERT_ARGS(io_stringhandle_readall_s)
}

static PIOOFF_T
io_stringhandle_tell(PARROT_INTERP, ARGMOD(PMC *handle))
{
    ASSERT_ARGS(io_stringhandle_tell)
}

static INTVAL
io_stringhandle_seek(PARROT_INTERP, ARGMOD(PMC *handle))
{
    ASSERT_ARGS(io_stringhandle_seek)
}

static INTVAL
io_stringhandle_peek(PARROT_INTERP, ARGMOD(PMC *handle))
{
    ASSERT_ARGS(io_stringhandle_peek_b)
}

static INTVAL
io_stringhandle_open(PARROT_INTERP, ARGMOD(PMC *handle), ARGIN(STRING *path), INTVAL flags, ARGIN(STRING *mode))
{
    ASSERT_ARGS(io_stringhandle_open)
}

static INTVAL
io_stringhandle_is_open(PARROT_INTERP, ARGMOD(PMC *handle))
{
    ASSERT_ARGS(io_stringhandle_is_open)
}

static INTVAL
io_stringhandle_close(PARROT_INTERP, ARGMOD(PMC *handle), INTVAL autoflush)
{
    ASSERT_ARGS(io_stringhandle_close)

    SETATTR_StringHandle_read_offset(interp, handle, 0);
    return
}
