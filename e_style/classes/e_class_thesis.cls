% =================================================================
% e_class_notes.cls
% A LaTeX class for thesis, based on user-provided style files.
% Version 1.0
% =================================================================


\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{e_class_thesis}[Thesis Class]

% --- 1. Process options and load the base 'book' class ---
% Pass any options given to this class (e.g., 'twoside', 'a4paper') to the base 'book' class.
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{book}}
\ProcessOptions\relax
\LoadClass{book}

% --- 2. Load the common style package ---
% This single command loads all your modular style components (packages, commands, colors, etc.).
\RequirePackage{e_standard_doc}
\RequirePackage{e_frontbackmatter_formal} % Load the front and back matter package
\RequirePackage{e_title_caligraphy_chap}


% --- 3. Define user-facing commands for thesis metadata ---


% --- 4. Define commands and environments for document structure ---



% --- 5. Define Thesis-specific Formatting ---
% This section contains styling for chapters and ToC from general.tex

%-----------------------------------------------------------------------


\endinput