% =================================================================
% e_class_notes.cls
% A LaTeX class for article and reports, based on user-provided style files.
% Version 1.0
% =================================================================

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{e_class_report}[Report and Article Class]

% --- Class Options ---
% Process standard options for the article class (e.g., 10pt, 11pt, 12pt, a4paper)
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
% Set default options
\ExecuteOptions{12pt, a4paper}
% Process given options
\ProcessOptions\relax
% Load the base class
\LoadClass{article}


\RequirePackage{e_common_style}
\RequirePackage{e_frontbackmatter_simple}

\endinput