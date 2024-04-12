def weighted_regression(x_reg, y_reg, weight_reg, model):
    """
    Function to compute regression parameter weighted by a matrix (e.g. r2 value),
    where the regression model is y = 1/(cx) + d.

    Parameters
    ----------
    x_reg : array (1D)
        x values to regress
    y_reg : array
        y values to regress
    weight_reg : array (1D) 
        weight values (0 to 1) for weighted regression
    model : str
        Type of regression model, either 'pcm' for the original model or 'linear' for a linear model.

    Returns
    -------
    coef_reg : float or array
        regression coefficient(s)
    intercept_reg : float or str
        regression intercept or a string indicating no intercept (for linear model)
    """

    import numpy as np
    from scipy.optimize import curve_fit
    from sklearn import linear_model
    
    x_reg = np.array(x_reg)
    y_reg = np.array(y_reg)
    weight_reg = np.array(weight_reg)

    # Filter out NaN values
    x_reg_nan = x_reg[(~np.isnan(x_reg) & ~np.isnan(y_reg))]
    y_reg_nan = y_reg[(~np.isnan(x_reg) & ~np.isnan(y_reg))]
    weight_reg_nan = weight_reg[~np.isnan(weight_reg)]
    
    if model == 'pcm':
        # Define the model function
        def model_function(x, c, d):
            return 1 / (c * x) + d
       
        # Perform curve fitting
        params, _ = curve_fit(model_function, x_reg_nan, y_reg_nan, sigma=weight_reg_nan)
        
        # Extract parameters
        c, d = params
        
        return c, d
    
    elif model == 'linear':
        regr = linear_model.LinearRegression()
        
        # Filter out NaN values
        x_reg_nan = x_reg_nan.reshape(-1, 1)
        y_reg_nan = y_reg_nan.reshape(-1, 1)
        
        regr.fit(x_reg_nan, y_reg_nan, sample_weight=weight_reg_nan)
        coef_reg, intercept_reg = regr.coef_, regr.intercept_

        return coef_reg, intercept_reg
    
    else:
        raise ValueError("Invalid model type. Supported models are 'pcm' and 'linear'.")

def bootstrap_ci_median(data, n_bootstrap=1000, ci_level=0.95):
    import numpy as np
    n = len(data)
    bootstrap_samples = np.random.choice(data, size=(n_bootstrap, n), replace=True)
    medians = np.nanmedian(bootstrap_samples, axis=1)
    lower_ci = np.percentile(medians, (1 - ci_level) / 2 * 100)
    upper_ci = np.percentile(medians, (1 + ci_level) / 2 * 100)
    return lower_ci, upper_ci

def bootstrap_ci_mean(data, n_bootstrap=1000, ci_level=0.95):
    import numpy as np
    n = len(data)
    bootstrap_samples = np.random.choice(data, size=(n_bootstrap, n), replace=True)
    means = np.mean(bootstrap_samples, axis=1)
    lower_ci = np.percentile(means, (1 - ci_level) / 2 * 100)
    upper_ci = np.percentile(means, (1 + ci_level) / 2 * 100)
    return lower_ci, upper_ci




def r2_score_surf(bold_signal, model_prediction):
    """
    Compute r2 between bold signal and model. The gestion of nan values 
    is down with created a non nan mask on the model prediction 

    Parameters
    ----------
    bold_signal: bold signal in 2-dimensional np.array (time, vertex)
    model_prediction: model prediction in 2-dimensional np.array (time, vertex)
    
    Returns
    -------
    r2_scores: the R2 score for each vertex
    """
    import numpy as np
    from sklearn.metrics import r2_score
    
    # Check for NaN values in both bold_signal and model_prediction
    nan_mask = np.isnan(model_prediction).any(axis=0) | np.isnan(bold_signal).any(axis=0)
    valid_vertices = ~nan_mask
    
    # Set R2 scores for vertices with NaN values to NaN
    r2_scores = np.full_like(nan_mask, np.nan, dtype=float)
    
    # Compute R2 scores for vertices without NaN values
    r2_scores[valid_vertices] = r2_score(bold_signal[:, valid_vertices], model_prediction[:, valid_vertices], multioutput='raw_values')
    
    return r2_scores

# def linear_regression_surf(bold_signal, model_prediction):
#     """
#     Perform linear regression analysis between model predictions and BOLD signals across vertices.

#     Parameters:
#     bold_signal (numpy.ndarray): Array of BOLD signal data with shape (time_points, vertices).
#     model_prediction (numpy.ndarray): Array of model prediction data with shape (time_points, vertices).

#     Returns:
#     results (list): List containing the results of linear regression analysis for each vertex.
#                     Each element in the list is a named tuple containing the following fields:
#                     - slope: Slope of the regression line.
#                     - intercept: Intercept of the regression line.
#                     - rvalue: Correlation coefficient.
#                     - pvalue: Two-sided p-value for a hypothesis test whose null hypothesis is
#                               that the slope is zero, using Wald Test with t-distribution of the test statistic.
#                     - stderr: Standard error of the estimated gradient.

#     Note:
#     The function checks for NaN values in both bold_signal and model_prediction.
#     It also identifies and excludes vertices with identical values or containing NaNs.

#     """

#     # Import necessary libraries
#     import numpy as np
#     from scipy import stats

#     # Check for NaN values in both bold_signal and model_prediction
#     nan_mask = np.isnan(model_prediction).any(axis=0) | np.isnan(bold_signal).any(axis=0)

#     # Mask for checking identical values along axis 0 in model_prediction
#     identical_values_mask = (model_prediction[:-1] == model_prediction[1:]).all(axis=0)

#     # Combining nan_mask and identical_values_mask
#     invalid_mask = nan_mask | identical_values_mask

#     valid_vertices = np.where(~invalid_mask)[0]

#     results = []  # List to store the results for each vertex
#     for vert in valid_vertices:
#         result = stats.linregress(x=model_prediction[:, vert],
#                                   y=bold_signal[:, vert],
#                                   alternative='two-sided')
#         results.append(result)

#     return results

def linear_regression_surf(bold_signal, model_prediction, correction=None, alpha=None):
    """
    Perform linear regression analysis between model predictions and BOLD signals across vertices.

    Parameters:
    bold_signal (numpy.ndarray): Array of BOLD signal data with shape (time_points, vertices).
    model_prediction (numpy.ndarray): Array of model prediction data with shape (time_points, vertices).
    correction (str, optional): Type of multiple testing correction.
                                Supported methods: 'bonferroni', 'sidak', 'holm-sidak',
                                'holm', 'simes-hochberg', 'hommel', 'fdr_bh', 'fdr_by', 'fdr_tsbh', 'fdr_tsbky'.
                                Default is 'fdr_bh'.
    alpha (float or list of floats, optional): The significance level(s) for the tests. Default is 0.01.

    Returns:
    vertex_results (numpy.ndarray): Array containing the results of linear regression analysis for each vertex.
                                     The shape of the array is (n_output, n_vertex), where n_output = slope, intercept, rvalue, pvalue + p_values_corrected for each alpha.

    Note:
    The function checks for NaN values in both bold_signal and model_prediction.
    It also identifies and excludes vertices with identical values or containing NaNs.
    """

    # Import 
    import numpy as np
    from scipy import stats
    from statsmodels.stats.multitest import multipletests
    
    if not isinstance(alpha, list):
        alpha = [alpha]
        
    # Check for NaN values in both bold_signal and model_prediction
    nan_mask = np.isnan(model_prediction).any(axis=0) | np.isnan(bold_signal).any(axis=0)

    # Mask for checking identical values along axis 0 in model_prediction
    identical_values_mask = (model_prediction[:-1] == model_prediction[1:]).all(axis=0)

    # Combining nan_mask and identical_values_mask
    invalid_mask = nan_mask | identical_values_mask

    valid_vertices = np.where(~invalid_mask)[0]

    num_vertices = bold_signal.shape[1]
    # Number of outputs per vertex (slope, intercept, rvalue, pvalue ) + the corrected p-values
    num_output = 5 + len(alpha) 

    # Array to store results for each vertex
    vertex_results = np.full((num_output, num_vertices),np.nan)  

    # Store p-values before correction
    p_values = np.full(num_vertices,np.nan)

    for i, vert in enumerate(valid_vertices):
        result = stats.linregress(x=model_prediction[:, vert],
                                  y=bold_signal[:, vert],
                                  alternative='two-sided')
        p_values[vert] = result.pvalue

        # Store results in the array
        vertex_results[:, vert] = [result.slope, result.intercept, result.rvalue, result.pvalue, result.stderr] + [np.nan]*len(alpha)  
    
    if not correction :
        return vertex_results
    # Apply multiple testing correction
    else :
        for n_alphas, alpha_val in enumerate(alpha):
            p_values_corrected = multipletests(p_values[valid_vertices], method=correction, alpha=alpha_val)[1]
            vertex_results[5 + n_alphas, valid_vertices] = p_values_corrected
    
        
    
    
        return vertex_results


def multipletests_surface(pvals, correction='fdr_tsbh', alpha=0.01):
    """
    Perform multiple testing correction for surface data.

    Parameters:
        pvals (numpy.ndarray): Array of p-values.
        correction (str, optional): Method of multiple testing correction. Default is 'fdr_tsbh'.
        alpha (float or list of float, optional): Significance level(s) for the correction.
            Can be a single float or a list of floats for multiple levels. Default is 0.01.

    Returns:
        numpy.ndarray: Array of corrected p-values corresponding to the input p-values.
    """
    # Import
    import numpy as np
    from statsmodels.stats.multitest import multipletests
    
    # If alpha is not already a list, convert it into a list
    if not isinstance(alpha, list):
        alpha_list = [alpha]
    else:
        alpha_list = alpha

    # Check for NaN values in pvals
    nan_mask = np.isnan(pvals)
    valid_vertices = np.where(~nan_mask)[0]

    # Initialize array to store corrected p-values
    corrected_pvals = np.full((len(alpha_list), pvals.shape[0]), np.nan)

    # Perform correction for each specified alpha level
    for n_alpha, alpha_val in enumerate(alpha_list):
        # Perform multiple testing correction and retrieve corrected p-values
        _, p_values_corrected, _, _ = multipletests(pvals[valid_vertices], method=correction, alpha=alpha_val)
        corrected_pvals[n_alpha, valid_vertices] = p_values_corrected

    return corrected_pvals

        
   
 
    