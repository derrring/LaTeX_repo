% =================================================================
% e_class_notes.cls
% A LaTeX class for thesis, based on user-provided style files.
% Version 1.0
% =================================================================


\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{e_class_thesis}[Thesis Class]

% --- Class Options ---

% The \makeatletter and \makeatother must wrap the entire block
% where commands with "@" are defined and used.
\makeatletter

% CJK switch - must be defined BEFORE loading packages
\newif\ifcjk
\cjkfalse % Default to CJK support DISABLED

% 12pt switch
\newif\if@e@twelvept
\@e@twelveptfalse

% Declare CJK options
\DeclareOption{cjk}{\cjktrue}
\DeclareOption{nocjk}{\cjkfalse}

% When the '12pt' option is found, pass it to the base class
\DeclareOption{12pt}{
    \PassOptionsToClass{\CurrentOption}{book}
    \@e@twelvepttrue
}

% Pass unknown options to base class
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{book}}

\ProcessOptions\relax
\LoadClass{book}

\makeatother
% --- 2. Load the common style package ---
% This single command loads all your modular style components (packages, commands, colors, etc.).
\RequirePackage{e_standard_doc}
\RequirePackage{e_frontbackmatter_formal} % Load the front and back matter package
\RequirePackage{e_title_caligraphy_chap}


% --- 3. Define user-facing commands for thesis metadata ---


% --- 4. Define commands and environments for document structure ---




% --- 5. Define Thesis-specific Formatting ---
% This section contains styling for chapters and ToC from general.tex
\linespread{1.1}



% Override only for 12pt option


%-----------------------------------------------------------------------


\endinput
