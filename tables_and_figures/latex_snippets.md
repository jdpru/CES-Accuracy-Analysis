# LaTeX Code for Figures and Tables

## Tables (15 total)

```latex
% =============================================================================
% MAIN RMSE TABLES
% =============================================================================

% Table A: CES-Weighted RMSE by Variable and Year
\input{output/rmse_ces_weighted_all.tex}

% Table B: CES-Weighted RMSE by Variable and Year (Separated by Variable Type)
\input{output/rmse_ces_weighted_by_type.tex}

% Table: Unweighted RMSE
\input{output/rmse_unweighted.tex}

% Table: CES Comparison
\input{output/ces_comparison_table.tex}

% =============================================================================
% PRIMARY VS SECONDARY ANALYSIS
% =============================================================================

% Table: Primary vs Secondary Delta by Year
\input{output/primary_secondary_delta.tex}

% =============================================================================
% TREND REGRESSION TABLES
% =============================================================================

% Table: RMSE Trend Regression by Variable
\input{output/rmse_trend_regression_by_variable.tex}

% Table: Error Trend Regression by Class
\input{output/error_trend_regression_by_class.tex}

% Table: Error Trend Regression by Variable
\input{output/error_trend_regression_by_variable.tex}

% =============================================================================
% WINSORIZED ANALYSIS TABLES
% =============================================================================

% Table: Winsorized vs Normal RMSE Trends by Class
\input{output/rmse_trends_winsorized_by_class.tex}

% Table: Winsorization Sensitivity Analysis
\input{output/winsor_sensitivity.tex}

% Table: Observation Counts per Variable per Year
\input{output/obs_counts_per_variable_year.tex}

% =============================================================================
% COMPARISON TABLES
% =============================================================================

% Table: ANESRake Full vs Restricted Comparison
\input{output/anesrake_full_vs_restricted_comparison.tex}

% Table: Candidate vs Party Specificity
\input{output/candidate_vs_party_specificity.tex}

% Table: Party vs Candidate RMSE Comparison
\input{output/rmse_party_vs_candidate_comparison.tex}

% Table: RMSE by Office and Year
\input{output/rmse_by_office_year.tex}
```

## Figures (27 total)

```latex
% =============================================================================
% RMSE BY CLASS AND WEIGHTING
% =============================================================================

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/rmse_by_class_histogram.png}
    \caption{RMSE by Variable Class (Matching + Post-Stratification)}
    \label{fig:rmse_by_class_histogram}
\end{figure}

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/rmse_by_weighting_method_class.png}
    \caption{RMSE by Weighting Method and Variable Class}
    \label{fig:rmse_by_weighting_method_class}
\end{figure}

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/rmse_by_weighting_method_validity_scheme.png}
    \caption{RMSE by Weighting Method and Validity Scheme}
    \label{fig:rmse_by_weighting_method_validity_scheme}
\end{figure}

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/rmse_by_weighting_method_validity_scheme_comparison.png}
    \caption{RMSE by Weighting Method and Validity Scheme (Comparison)}
    \label{fig:rmse_by_weighting_method_validity_scheme_comparison}
\end{figure}

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/rmse_by_weighting_method_validity_scheme_filtered.png}
    \caption{RMSE by Weighting Method and Validity Scheme (Filtered)}
    \label{fig:rmse_by_weighting_method_validity_scheme_filtered}
\end{figure}

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/rmse_by_year_weighting_comparison.png}
    \caption{RMSE by Year: Weighting Method Comparison}
    \label{fig:rmse_by_year_weighting_comparison}
\end{figure}

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/error_reduction_ces_weights_by_type.png}
    \caption{Error Reduction from CES Weighting by Variable Class}
    \label{fig:error_reduction_ces_weights_by_type}
\end{figure}

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/rmse_reduction_by_office.png}
    \caption{RMSE Reduction from CES Weighting by Office}
    \label{fig:rmse_reduction_by_office}
\end{figure}

% =============================================================================
% ANESRAKE COMPARISONS
% =============================================================================

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/anesrake_full_vs_restricted.png}
    \caption{ANESRake Full vs Restricted Validity Schemes}
    \label{fig:anesrake_full_vs_restricted}
\end{figure}

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/anesrake_full_vs_restricted_comparison.png}
    \caption{ANESRake Full vs Restricted Comparison}
    \label{fig:anesrake_full_vs_restricted_comparison}
\end{figure}

% =============================================================================
% PRIMARY VS SECONDARY VARIABLE ANALYSIS
% =============================================================================

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/primary_vs_secondary_by_year_stacked.png}
    \caption{Primary vs Secondary Variable Accuracy by Year (Stacked)}
    \label{fig:primary_vs_secondary_by_year_stacked}
\end{figure}

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/error_distribution_primary_vs_secondary_by_class.png}
    \caption{Error Distribution: Primary vs Secondary Variables by Class}
    \label{fig:error_distribution_primary_vs_secondary_by_class}
\end{figure}

% =============================================================================
% ERROR DISTRIBUTIONS
% =============================================================================

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/error_distribution_by_class.png}
    \caption{Distribution of Absolute Errors by Variable Class}
    \label{fig:error_distribution_by_class}
\end{figure}

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/error_distribution_by_class_sidebyside.png}
    \caption{Distribution of Absolute Errors by Variable Class (Side-by-Side)}
    \label{fig:error_distribution_by_class_sidebyside}
\end{figure}

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/error_distribution_by_race_grid.png}
    \caption{Distribution of Errors by Candidate Choice Race}
    \label{fig:error_distribution_by_race_grid}
\end{figure}

% =============================================================================
% TRENDS OVER TIME
% =============================================================================

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/error_trends_over_time.png}
    \caption{RMSE Trends Over Time by Variable Class}
    \label{fig:error_trends_over_time}
\end{figure}

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/rmse_trends_always_secondary.png}
    \caption{RMSE Trends for Always-Secondary Variables}
    \label{fig:rmse_trends_always_secondary}
\end{figure}

% =============================================================================
% CANDIDATE CHOICE / RACE SALIENCE
% =============================================================================

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/rmse_by_office_federal_state.png}
    \caption{Candidate Choice Accuracy by Government Level}
    \label{fig:rmse_by_office_federal_state}
\end{figure}

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/rmse_by_office_salience.png}
    \caption{Candidate Choice Accuracy by Race Salience}
    \label{fig:rmse_by_office_salience}
\end{figure}

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/rmse_by_office_salience_party.png}
    \caption{Candidate Choice Accuracy by Race Salience (Party-Level Specificity)}
    \label{fig:rmse_by_office_salience_party}
\end{figure}

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/rmse_by_office_year_heatmap.png}
    \caption{RMSE by Office and Year (Heatmap)}
    \label{fig:rmse_by_office_year_heatmap}
\end{figure}

% =============================================================================
% PARTY VS CANDIDATE SPECIFICITY
% =============================================================================

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/candidate_vs_party_specificity.png}
    \caption{Candidate vs Party Level Specificity Comparison}
    \label{fig:candidate_vs_party_specificity}
\end{figure}

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/rmse_party_vs_candidate_comparison.png}
    \caption{Party vs Candidate Specificity: RMSE Comparison}
    \label{fig:rmse_party_vs_candidate_comparison}
\end{figure}

% =============================================================================
% COMPETITIVENESS ANALYSIS
% =============================================================================

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/rmse_by_competitiveness_histogram.png}
    \caption{RMSE by Race Competitiveness}
    \label{fig:rmse_by_competitiveness_histogram}
\end{figure}

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/error_vs_competitiveness_improved.png}
    \caption{Error vs Race Competitiveness}
    \label{fig:error_vs_competitiveness_improved}
\end{figure}

% =============================================================================
% U.S. HOUSE / CONGRESSIONAL DISTRICT ANALYSIS
% =============================================================================

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/us_house_cd_size_distribution.png}
    \caption{U.S. House: Congressional District Sample Size Distribution}
    \label{fig:us_house_cd_size_distribution}
\end{figure}

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/us_house_error_by_cd_size.png}
    \caption{U.S. House Accuracy by Congressional District Size}
    \label{fig:us_house_error_by_cd_size}
\end{figure}
```

---

**Summary: 15 tables, 27 figures**

\begin{figure}[H]
    \centering
    \includegraphics[width=1\linewidth]{output/primary_secondary_delta_by_year.png}
    \caption{Primary vs Secondary RMSE Delta by Year (Excluding Turnout \& Registration)}
    \label{fig:primary_secondary_delta_by_year}
\end{figure}
