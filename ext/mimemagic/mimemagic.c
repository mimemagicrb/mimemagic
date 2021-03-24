#include <ruby.h>
#include "extconf.h"

void Init_mimemagic(void) {
    VALUE cMimeMagic;

    cMimeMagic = rb_const_get(rb_cObject, rb_intern("MimeMagic"));

    rb_define_const(cMimeMagic, "DATABASE_PATH", rb_str_new(MIMEDB_PATH, strlen(MIMEDB_PATH)));
}
