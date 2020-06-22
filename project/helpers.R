# helpers.R
# Damir Pulatov

library(llama)

# build data for scatter plot
build_data = function(ids, m1, m2) {
  data = data.frame(instance_id = ids, x = m1, y = m2)
  return(data)
}


# get single best solver 
get_sbs = function(data) {
  sbs = llama:::singleBest(data)
  sbs = list(predictions = sbs)
  attr(sbs, "hasPredictions") = TRUE
  return(sbs)
}


# get virtual best solver
get_vbs = function(data) {
  vbs = llama:::vbs(data)
  vbs = list(predictions = vbs)
  attr(vbs, "hasPredictions") = TRUE
  return(vbs)
}


# compute mean mcp or gap closed
compute_metric = function(data, method, selector) {
  if(method == "mcp") {
    val = misclassificationPenalties(data, selector)
  } else if(method == "par10") {
    val = parscores(data, selector)
  }
  return(val)
}

# compute percentage of closed gap
compute_gap =  function(model_val, vbs_val, sbs_val) {
  return(round(1 - (model_val - vbs_val) / (sbs_val - vbs_val), 2) * 100)
}


# wrapper for loading scenario
read_scenario = function(switch, path = NULL, scenario_name = NULL) {
  if(switch == "ASlib") {
    scenario = getCosealASScenario(scenario_name)
    return(scenario)
  } else if (switch == "Custom") {
    scenario = parseASScenario(path)
    return(scenario)
  }
}


# make plot text
make_text = function(metric, selector1, selector2) {
  if(metric == "mcp") {
    return(paste("Misclassification Penalties for ", selector1, " vs. ", selector2))
  } else if (metric == "par10") {
    return(paste("PAR10 Scores for ", selector1, " vs. ", selector2))
  }
}


# build data from scenario
get_data = function(scenario) {
  llama.cv = convertToLlamaCVFolds(scenario)
  data = fixFeckingPresolve(scenario, llama.cv)
  return(data)
}


# build model with llama with scenario split into train/test
build_model = function(learner_name, data) {
  learner = makeImputeWrapper(learner = setHyperPars(makeLearner(learner_name)),
                classes = list(numeric = imputeMean(), integer = imputeMean(), logical = imputeMode(),
                factor = imputeConstant("NA"), character = imputeConstant("NA")))
  model = regression(learner, data)
  return(model)
}


# wrapper for building/uploading model
# need assert that loaded model has predictions
create_model = function(type, learner_name, file_name, data) {
  if(type == "mlr/llama") {
    model = build_model(learner_name, data)
  } else if(type == "Custom") {
    var_name = load(file_name$datapath) 
    model = get(var_name)
  }
  return(model)
}


summarize = function(type, mcp1, mcp2, par1, par2) {
  if(type == "mcp") {
    data = data.frame("x" = mcp1, "y" = mcp2)
  } else if(type == "par10") {
    data = data.frame("x" = par1, "y" = par2)
  }
  return(data)
}


get_ids = function(data) {
  ids = data$data[unlist(data$test), data$ids]
  return(ids)
}