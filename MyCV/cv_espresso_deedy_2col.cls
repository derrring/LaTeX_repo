%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CV Espresso Deedy Class - 2 Column
%
% Based on the original Deedy Resume 2-Column template
% Refactored into .sty + .cls architecture
%
% Author: Based on Deedy Resume template
% License: MIT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{cv_espresso_deedy_2col}[2025/08/29 CV Espresso Deedy class - 2 Column version]

% Handle class options
\DeclareOption{print}{\def\@cv@print{}}
\DeclareOption{a4}{\PassOptionsToPackage{a4}{cv_espresso_deedy_common}}
\DeclareOption{a4paper}{\PassOptionsToPackage{a4paper}{cv_espresso_deedy_common}}
\DeclareOption{letter}{\PassOptionsToPackage{letter}{cv_espresso_deedy_common}}
\DeclareOption{letterpaper}{\PassOptionsToPackage{letterpaper}{cv_espresso_deedy_common}}
\DeclareOption*{
  \PassOptionsToClass{\CurrentOption}{article}%
}
\ProcessOptions\relax

% Load base article class (force single column to avoid paracol conflicts)
\LoadClass[onecolumn]{article}

% Load common CV functionality
\RequirePackage{cv_espresso_deedy_common}

% 2-Column specific packages
\RequirePackage{paracol}
\RequirePackage{enumitem}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PARACOL CONFIGURATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set column separation and ratios
\setlength{\columnsep}{2em}
\setlength{\columnseprule}{0pt}
\colseprulecolor{white}

% Default column ratio (35% left, 65% right)
\columnratio{0.35}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2-COLUMN USAGE NOTES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Users should structure their document like this:
%
% \begin{document}
% \cvnamesection{First}{Last}{Contact Info}
% \cvlastupdated
%
% \begin{paracol}{2}
% % Left column content
% \section{Skills}
% ...
%
% \switchcolumn
% % Right column content  
% \section{Experience}
% ...
% \end{paracol}
% \end{document}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2-COLUMN LIST ENVIRONMENTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% User-defined environments for better LaTeX syntax
\newenvironment{cventrylist}
  {\begin{itemize}[leftmargin=1.2em,itemsep=2pt,parsep=1pt,topsep=0pt,partopsep=0pt]}
  {\end{itemize}}

\newenvironment{cvitemlist}
  {\begin{itemize}[leftmargin=1.2em,itemsep=2pt,parsep=0pt,topsep=0pt,partopsep=0pt]}
  {\end{itemize}}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2-COLUMN ITEM COMMANDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Define cventry for 2-column layout (no automatic \item)
\newcommand{\cventry}[4]{%
  \cvrunsubsection{#1}
  \cvdescript{#2}
  \cvlocation{#3}
  \ifstrempty{#4}{}{%
    \begin{cvitemlist}%
      #4%
    \end{cvitemlist}%
  }%
  \vspace{1pt}
}

% Define cvtext for 2-column layout
\newcommand{\cvtext}[4]{%
  \cvrunsubsection{#1}
  \cvdescript{#2}
  \cvlocation{#3}
  \ifstrempty{#4}{}{%
    \vspace{\topsep}%
    #4%
  }%
  \cvsectionsep
}

% New minipage-based entry command for 2-column (no \item inside definition)
% Parameters: #1=Company/Institution, #2=Location, #3=Position/Degree, #4=Date
\newcommand{\cvtabentry}[4]{%
  \raisebox{1.5ex}[0pt][0pt]{%
    \begin{minipage}[t]{0.65\linewidth}
      \color{subheadings}\cvsubheadingfont\fontsize{11pt}{11pt}\selectfont{\scshape #1} \\
      \color{subheadings}\cvdescfont\fontsize{10pt}{12pt}\selectfont{\textit{#3}}
    \end{minipage}%
    \hfill%
    \begin{minipage}[t]{0.32\linewidth}
      \raggedleft%
      \color{headings}\cvlocationfont\fontsize{9pt}{9pt}\selectfont #2 \\
      \color{headings}\cvlocationfont\fontsize{9pt}{9pt}\selectfont{\textit{#4}}
    \end{minipage}%
  }%
  \vspace{1pt}%
}

