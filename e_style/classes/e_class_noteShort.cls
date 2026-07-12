% =================================================================
% e_class_noteShort.cls
% A LaTeX class for short notes with decorated math environments.
% Version 1.0
% =================================================================

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{e_class_noteShort}[2026/07/12 v1.0 Short notes class (decorated math)]

% --- Class Options (shared prologue: 12pt switch + deprecated cjk/nocjk) ---
\def\e@baseclass{article}
\input{sty_components/e_class_prologue.tex}


\RequirePackage{e_profile_standard}
\RequirePackage{e_frontbackmatter_simple}
\RequirePackage{e_title_fenced_sec}
\RequirePackage{e_math_env_deco}
\RequirePackage{e_heading_scale}


\endinput
