% =================================================================
% e_class_notes.cls
% A LaTeX class for lecture notes, based on user-provided style files.
% Version 1.0
% =================================================================

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{e_class_noteLong}[Lecture Notes Class]

% --- Class Options ---
% Process standard options for the article class (e.g., 10pt, 11pt, 12pt, a4paper)
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{book}}
% Process given options
\ProcessOptions\relax
% Load the base class
\LoadClass[12pt]{book}


\RequirePackage{e_standard_doc}
\RequirePackage{e_frontbackmatter_formal}
\RequirePackage{e_title_fenced_chap}
\RequirePackage{e_math_env_deco}


\endinput