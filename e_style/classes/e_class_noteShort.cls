% =================================================================
% e_class_notes.cls
% A LaTeX class for article and reports, based on user-provided style files.
% Version 1.0
% =================================================================

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{e_class_noteShort}[Article Class]

% --- Class Options ---
% Process standard options for the article class (e.g., 10pt, 11pt, 12pt, a4paper)
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
% Set default options
\ExecuteOptions{12pt, a4paper}
% Process given options
\ProcessOptions\relax
% Load the base class
\LoadClass{article}


\RequirePackage{e_standard_doc}
\RequirePackage{e_frontbackmatter_simple}
\RequirePackage{e_title_fenced_sec}
\RequirePackage{e_math_env_deco}


\endinput