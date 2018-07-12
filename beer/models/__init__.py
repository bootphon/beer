
from .bayesmodel import *
from .normal import *
from .normalset import *
from .mixture import *
from .hmm import *
from .ppca import *
from .pldaset import *
from .vae import *


_model_types = {
    'Normal': normal.create,
    'NormalSet': normalset.create,
    'Mixture': mixture.create,
    'HMM': None,
    'PPCA': ppca.create,
    'PLDASet': pldaset.create,
    'NonLinearSubspaceModel': vae.create_normal_vae,
    'BernoulliNonLinearSubspaceModel': vae.create_bernoulli_vae,
    'BetaNonLinearSubspaceModel': vae.create_beta_vae,
}


def create_model(conf, mean, variance, create_model_handle=None):
    '''Create one or several models from a YAML configuration string.

    Args:
        conf (dict): Dictionary containing the configuration of the
            model.
        mean (``torch.Tensor``): Mean of the data to initialize the
            model.
        variance (``torch.Tensor``): Variance of the data to initialize
            the model.

    Returns:
        :any:`BayesianModel` or a list of :any:`BayesianModel`

    '''
    requested_type = conf['type']
    if requested_type not in _model_types:
        raise ValueError('Unknown model type: {}'.format(requested_type))
    return _model_types[requested_type](conf, mean, variance, create_model)
