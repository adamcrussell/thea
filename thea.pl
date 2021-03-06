:- prolog_load_context(directory, Dir),
   file_directory_name(Dir, Lib),
   (   user:file_search_path(library, Lib)
   ->  true
   ;   asserta(user:file_search_path(library, Lib))
   ).

:-use_module('owl2_model.pl').
:-use_module('owl2_from_rdf.pl').
:-use_module('owl2_export_rdf.pl').
:-use_module('owl2_xml.pl').
:-use_module('owl2_util.pl').
:-use_module('owl2_io.pl').

