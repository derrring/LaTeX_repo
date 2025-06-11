% e_class_thesis.cls
% A custom thesis class , based on user-provided files.
% This class defines the document structure, layout, and metadata commands.

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
\RequirePackage{e_common_style}

% --- 3. Define user-facing commands for thesis metadata ---
% These commands will store the author's specific information.
% The \makeatletter allows us to use internal commands with '@'.
\makeatletter
\newcommand{\thesistitle}[1]{\def\@thesistitle{#1}}
\newcommand{\thesissubtitle}[1]{\def\@thesissubtitle{#1}}
\newcommand{\thesisauthor}[1]{\def\@thesisauthor{#1}}
\newcommand{\thesisemail}[1]{\def\@thesisemail{#1}}
\newcommand{\thesissupervisor}[1]{\def\@thesissupervisor{#1}}
\newcommand{\thesisdepartment}[1]{\def\@thesisdepartment{#1}}
\newcommand{\thesisuniversity}[1]{\def\@thesisuniversity{#1}}
\newcommand{\thesislocation}[1]{\def\@thesislocation{#1}}
\newcommand{\thesistime}[1]{\def\@thesistime{#1}}

% --- Set default values for some metadata ---
\thesisuniversity{Keio University}
\thesisdepartment{Graduate School of Science and Technology}
\thesistime{\today}
\makeatother

% --- 4. Define commands and environments for document structure ---
% This section absorbs the logic from your 'frontbackmatter/' directory.

% (A) Command to create the entire title page, based on titlepage.tex
\newcommand{\makecover}{%
  \begin{titlepage}
    \begin{center}
        \large
        \begingroup
        慶應義塾大学\\
        \vspace{0.5em}
        \MakeUppercase{\@thesisuniversity} \\
        \endgroup
        \vfill
        \begingroup
            % Use the internal variables defined by the metadata commands
            {\Huge \bfseries \@thesistitle}\\
            \vspace{1em}\MakeUppercase{\footnotesize \@thesissubtitle}\\
        \endgroup
        \vfill
        \begingroup
            {\normalsize \@thesisauthor\footnote{\@thesisemail}} \\
        \endgroup
        \vfill
        \@thesislocation\\
        \vspace{0.5em}
        \@thesistime%
        \vfill
    \end{center}
  \end{titlepage}
  % Add the titleback page logic, based on titleback.tex
  \cleardoublepage
  \thispagestyle{empty}
  \null\vfill
  \noindent\@thesisauthor: \textit{\@thesistitle,} \textcopyright\ \@thesistime
  \cleardoublepage
}

% (B) Environment for the abstract, based on abstract.tex
\newenvironment{abstractpage}{%
  \pdfbookmark[1]{Abstract}{Abstract}
  \chapter*{Abstract}
  \begin{center}
	  \begin{minipage}[h]{0.75\linewidth}
		  \begin{center}
			  Supervisor: \@thesissupervisor
			  {\footnotesize 
			  \vspace{1em}
			  \@thesisdepartment\\
			  \@thesisuniversity
			  }
		  \end{center}
	  \end{minipage}
  \end{center}
  \vspace{2em}
  \begin{center}
	  \begin{minipage}[h]{0.85\linewidth}
		  \begin{center}
			  ABSTRACT
		  \end{center}
		  \small
}{%
	  \end{minipage}
  \end{center}
  \cleardoublepage
}

% (C) Environment for acknowledgments, based on acknowledgments.tex
\newenvironment{acknowledgments}{%
    \pdfbookmark[1]{Acknowledgements}{acknowledgements}
    \chapter*{Acknowledgements}
}{%
    \cleardoublepage
}


% --- 5. Define Thesis-specific Formatting ---
% This section contains styling for chapters and ToC from general.tex

% (A) Chapter title formatting
\newcommand{\chapterNumber}{\fontsize{70}{0}\usefont{OT1}{Alegreya-OsF}{m}{n}}
\titleformat{\chapter}[display]
  {\normalfont\bfseries\large}
  {\vspace*{-3\baselineskip}\makebox[\linewidth][r]{\color{darklinkcolor}\chapterNumber\thechapter}}{11pt}
  {\raggedright\MakeUppercase}
  [\normalsize\vspace*{.8\baselineskip}\titlerule]

% (B) Table of Contents (ToC) formatting
\def\mydotfill{\unskip\nobreak\leaders\hbox{\hss\ .\hss}\hfill\nobreak\relax}
\etocsetstyle{part}
    {\begingroup\parindent 0pt \nobreak \etocskipfirstprefix}
    {\pagebreak[3]\bigskip}
    {\normalsize\rmfamily\centering \color{red} \etocifnumbered{Part \etocnumber{} -- }
    {}\MakeUppercase{\etocthename}\par} 
    {\endgroup}
\etocsetstyle{chapter}
    {\begingroup}
    {\addvspace{0.5em}\parindent0pt \color{black}\small}
    {\etocifnumbered{\etocnumber\hspace{0.5em} \MakeUppercase{\etocthename}\hfill  \etocpage\par \addvspace{0.25em}}
    {\MakeUppercase{\etocthename}\hfill \etocpage\par \addvspace{0.25em}}}
    {\endgroup\addvspace{0.2em}}
\etocsetstyle{section}
    {\begingroup\addvspace{0.25em}\leftskip0em\parindent0pt\smallskip}
    {\footnotesize}
    {\etocifnumbered{\etocnumber\hspace{0.3em} \etocname\mydotfill  \etocpage\par \addvspace{0.25em}}
    {\etocname\hfill \etocpage\par\addvspace{0.25em}}}
    {\endgroup\par\medskip}
% Add subsection and subsubsection if needed...

\endinput