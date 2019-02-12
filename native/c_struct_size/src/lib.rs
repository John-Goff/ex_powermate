#[macro_use] extern crate rustler;
#[macro_use] extern crate rustler_codegen;
#[macro_use] extern crate lazy_static;

use rustler::{Env, Term, NifResult, Encoder};
use std::mem;

mod atoms {
    rustler_atoms! {
        atom ok;
        //atom error;
        //atom __true__ = "true";
        //atom __false__ = "false";
    }
}

#[repr(C)]
struct PowerMate {
    seconds: i64,
    microseconds: i64,
    event_type: u16,
    code: u16,
    value: u32
}

rustler_export_nifs! {
    "Elixir.CStruct",
    [("struct_size", 0, struct_size)],
    None
}

fn struct_size<'a>(env: Env<'a>, _args: &[Term<'a>]) -> NifResult<Term<'a>> {
    Ok((atoms::ok(), mem::size_of::<PowerMate>()).encode(env))
}
