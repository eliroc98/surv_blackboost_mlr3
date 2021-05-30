################################################################################
library(mlr3)
library(mlr3misc)
library(mlr3proba)
library(mlr3tuning)
library(mlr3learners)
library(mlr3extralearners)
library(survivalmodels)
library(survival)
library(mboost)
################################################################################

#load dataset
gbcs <- mlr3proba::gbcs
dim(gbcs)

#select interesting variables 
gbcs2 <- gbcs[,c(5:12,15:16)]
dim(gbcs2)
summarytools::dfSummary(gbcs2, 
                        graph.col = F, 
                        valid.col = F)

#scale-normalize variables for better performance
gbcs2$menopause <- gbcs2$menopause-1
gbcs2$hormone <- gbcs2$hormone-1
gbcs2$size <- scale(gbcs2$size)
gbcs2$grade1 <- ifelse(gbcs2$grade==1, 1,0)
gbcs2$grade2 <- ifelse(gbcs2$grade==2, 1,0)
gbcs2$grade3 <- ifelse(gbcs2$grade==3, 1,0)
gbcs2$grade <- NULL
gbcs2$age <- scale(gbcs2$age)
gbcs2$nodes <- scale(gbcs2$nodes)
gbcs2$prog_recp <- scale(gbcs2$prog_recp)
gbcs2$estrg_recp <- scale(gbcs2$estrg_recp)

#see the gbcs dataset
str(gbcs2)
View(gbcs2)

################################################################################

#train test split
set.seed(123)
train_set = sample(nrow(gbcs2), 0.8 * nrow(gbcs2))
test_set = setdiff(seq_len(nrow(gbcs2)), train_set)


train_gbcs <- gbcs2[train_set, ]

test_gbcs <- gbcs2[test_set, ]

#create the task
train_task = TaskSurv$new(id = "train_gbcs", 
                          backend = train_gbcs, 
                          time = "survtime", 
                          event = "censdead")

test_task = TaskSurv$new(id = "test_gbcs", 
                         backend = test_gbcs, 
                         time = "survtime", 
                         event = "censdead")

################################################################################

#COX AS BASELINE

learner.cox = lrn("surv.coxph")

learner.cox$train(train_task)
learner.cox$model

prediction.cox = learner.cox$predict(test_task)
table(head(as.data.table(prediction.cox)))

prediction.cox$score()
#surv.harrell_c -------------> 0.6897718 

#TREE learner with BOOSTING
learner = lrn("surv.blackboost")
learner$param_set$ids()

#training
learner$train(train_task)
learner$model

#predictions
prediction <- learner$predict(test_task)
prediction


#score
prediction$score()
#surv.harrell_c  ---------------------->   0.7369682 

#################
learner = lrn("surv.blackboost")
learner$param_set$values <- list(family = 'coxph', 
                                 mstop = 100, 
                                 nu = 0.1, 
                                 stopintern = T,
                                 trace = T, 
                                 maxdepth = 4)
learner$train(train_task)
learner$model
prediction <- learner$predict(test_task)
prediction
prediction$score()
#################

#GRID-SEARCH for the best params above tested for fun

search_space = ps(
  mstop = p_int(lower = 70, upper = 130),
  nu = p_dbl(lower = 0.01, upper = 0.1),
  maxdepth = p_int(lower = 2, upper = 8),
  stopintern = p_lgl()
)

search_space

CVstrat = rsmp("cv", folds = 10)
measure = msr("surv.cindex")
print(measure)

combo <- trm("combo",
              list(trm("evals", n_evals = 50),
                   trm("stagnation")),
              any = TRUE
              )



instance = TuningInstanceSingleCrit$new(
  task = train_task,
  measure = measure,
  learner = learner,
  resampling = CVstrat,
  search_space = search_space,
  terminator = combo
)

instance
tuner = tnr("random_search")
tuner$optimize(instance)

instance$is_terminated
#number of optimal stap number
instance$result_learner_param_vals
#step number vs harrel_c
as.data.table(instance$archive)

#train with optimal stepnumber
learner$param_set$values = instance$result_learner_param_vals
learner$train(task_gbcs)
learner$model

prediction = learner$predict(test_gbcs)
prediction
prediction$score()


#0.7016681 harrel_c (optimized) (vecchio)

# CON RANDOM SEARCH
#mstop 130
#nu: 0.07058805
#maxdepth: 2
#stopintern TRUE
#surv.harrell_c: 0.7380778


#CON GRID SEARCH (PEGGIO)
#mstop 83
#nu: 0.1
#maxdepth: 6
#stopintern FALSE
#surv.harrell_c: 0.7373726
