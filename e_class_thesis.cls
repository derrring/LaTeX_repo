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
% Load the book class with 12pt as the default, based on your original file.
\LoadClass[12pt]{book}

% --- 2. Load the common style package ---
% This single command loads all your modular style components (packages, commands, colors, etc.).
\RequirePackage{es_common_style}
\RequirePackage{es_frontbackmatter_formal} % Load the front and back matter package

% --- 3. Define user-facing commands for thesis metadata ---


% --- 4. Define commands and environments for document structure ---



% --- 5. Define Thesis-specific Formatting ---
% This section contains styling for chapters and ToC from general.tex

%-----------------------------------------------------------------------
% Control the appearance of the title in mainmatter
% \titleformat provided by titlesec package
\renewcommand{\thepart}{\Roman{part}}
\titleformat{\part}%command
    [display]%shape
    {\normalfont\centering\large}%format
    {\thispagestyle{empty}\partname~\MakeUppercase{\thepart}}%label
    {1em}%sep
    {\color{darklinkcolor}\MakeUppercase}%beforcode
% Chapter number on inside
    % Chapter font
\newcommand{\chapterNumber}{\fontsize{70}{0}\usefont{OT1}{Alegreya-OsF}{m}{n}}

\titleformat{\chapter}[display]%{<commmand>}[<shape>]
  {\normalfont\bfseries\large} %<format>
  %{\MakeUppercase{\chaptertitlename}}{10pt} %{<label>}{<sep>}
  {\vspace*{-3\baselineskip}\makebox[\linewidth][r]{\color{darklinkcolor}\chapterNumber\thechapter}}{11pt}%{<label>}{<sep>}
  {\raggedright\MakeUppercase} %{<beforcode>}
  [\normalsize\vspace*{.8\baselineskip}\titlerule] %[<aftercode>]



\endinput