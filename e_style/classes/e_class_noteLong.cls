% =================================================================
% e_class_notes.cls
% A LaTeX class for lecture notes, based on user-provided style files.
% Version 1.0
% =================================================================

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{e_class_note}[Lecture Notes Class]

% --- Class Options ---
% Process standard options for the article class (e.g., 10pt, 11pt, 12pt, a4paper)
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{book}}
% Set default options
\ExecuteOptions{12pt}
% Process given options
\ProcessOptions\relax
% Load the base class
\LoadClass{book}


\RequirePackage{e_common_style}
\RequirePackage{e_frontbackmatter_formal}




\endinput