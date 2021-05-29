## surv_blackboost_mlr3 

The function `surv.blackboost` from the package `mlr3extralearners` implements a gradient boosting algorithm that can be fitted for censored data. Similarly to other packages, blackboost implements the classical algorithm with regression trees as base learners. The peculiarity of blackboost is the possibility to change the default loss function to be optimized for the terminal regions of each tree. Blackboost allows to do so either by specifying either a custom loss function or by selecting a preexisting one under the `family` argument. Moreover, the performances of the model can be implemented further by specifying a variety of tree controls. In fact, blackboost relies on `partykit::ctree`, which offers a wide range of parameters for conditional inference trees. You can type `args(partykit::ctree_control)` for more details on the tree controls parameters.

`mlr3` offers an intuitive and interconnected set of extension packages that we are going to use with respect to different aspects of this explanatory project.
We can start off by installing all the required packages:

``` r
{
install.packages(c("mlr3", "mlr3extralearners", "mlr3tuning", "mlr3proba", "mlr3pipelines", mlr3misc", "survivalmodels", "mboost", "paradox", "parallell", "stabs", ))
}
```
___

Before moving on with the next topic, let us dive deeper in the functionality of blackboost by taking a look at its parameters and their respective default values:

``` r 
{
install_learners('surv.blackboost')
learner = lrn("surv.blackboost")
learner$param_set
}
```
___
