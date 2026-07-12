% =================================================================
% e_class_thesis.cls
% A LaTeX class for theses and dissertations.
% Version 1.0
% =================================================================


\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{e_class_thesis}[Thesis Class]

% --- Class Options (shared prologue: 12pt switch + deprecated cjk/nocjk) ---
\def\e@baseclass{book}
\input{sty_components/e_class_prologue.tex}
% --- 2. Load the common style package ---
% This single command loads all your modular style components (packages, commands, colors, etc.).
\RequirePackage{e_profile_standard}
\RequirePackage{e_frontbackmatter_formal} % Load the front and back matter package
\RequirePackage{e_title_caligraphy_chap}
\RequirePackage{e_heading_scale}


% --- 3. Define user-facing commands for thesis metadata ---


% --- 4. Define commands and environments for document structure ---




% --- 5. Define Thesis-specific Formatting ---
% This section contains styling for chapters and ToC from general.tex
\linespread{1.1}

% Thesis convention: TOC shows chapters + sections (no subsections).
% Package default in c130_toc.tex is 2; thesis overrides to 1.
\setcounter{tocdepth}{1}



% Override only for 12pt option


%-----------------------------------------------------------------------


\endinput
