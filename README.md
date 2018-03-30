BEER: the Bayesian Speech Recognizer
====================================

Beer is a toolkit that provide Bayesian machine learning tools for
speech technologies.

Beer is currently under construction and many things are subject to changes !

Requirements
------------

Beer is built upon the [pytorch](http://pytorch.org)
library. Note that we need pytorch to be installed from the master
branch as some features are not yet present in the Anaconda package. 
Besides, it also requires [numpy](http://www.numpy.org) and
[scipy](https://www.scipy.org/scipylib/index.html).  Finally, the
examples notebook use [bokeh](https://bokeh.pydata.org/en/latest/) for
visualtization.


Installation
------------

In a terminal type.

```
  $ python setup.py install
  
```

This will install ``beer`` and eventually ``numpy`` and ``sicpy``
if there are not install yet. Note that it will not 
automatically install ``pytorch``. Preferlease  to the
[pytorch documentation](https://github.com/pytorch/pytorch) 
to install it.


Usage
-----

Have a look to our [examples](https://github.com/beer-asr/beer/tree/install/examples)
to get started with beer.
