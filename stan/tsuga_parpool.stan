data {
	// same as in the pooled model
	int <lower=0> n; 
	int <lower=1> n_trees [n]; 
	int <lower=0> died [n]; 
	vector [n] precip;
	
	// grouping variables
	int <lower=1> n_groups;
	int <lower=1, upper = n_groups> year_id [n];

}
parameters {
	// one intercept and one slope per group
	vector [n_groups] a;
	vector [n_groups] b;
	
	// hyperparameters describe higher-level structure in the data
	// in this case both the a's and b's come from populations
	// with their own mean and variance to be estimated from the data
	real a_mu;
	real <lower=0> a_sig;
	real b_mu;
	real <lower=0> b_sig;

}
transformed parameters {
	vector <lower=0, upper=1> [n] p;
	
	for(i in 1:n) {
		int gid = year_id[i];
		p[i] = inv_logit(a[gid] + b[gid] * precip[i]);
	}
}
model {
	died ~ binomial(n_trees, p);
	
	// The priors are now estimated from the data
	a ~ normal(a_mu, a_sig);
	b ~ normal(b_mu, b_sig);
	
	// hyperpriors describe what we know about higher (group-level) structure
	a_mu ~ normal(0, 20);
	b_mu ~ normal(0, 20);
	// half cauchy is common for hierarchical stdev
	a_sig ~ cauchy(0, 20);
	b_sig ~ cauchy(0, 20);
	
}
generated quantities {
	// we use generated quantities to keep track of log likelihood and
	// deviance, useful for model selection
	// and also to perform poserior predictive simulations
	real deviance = 0;
	vector [n] loglik;
	int ppd_died [n];
	for (i in 1:n) {
		loglik[i] = binomial_lpmf(died[i] | n_trees[i], p[i]);
		deviance += loglik[i];
		ppd_died[i] = binomial_rng(20, p[i]);
	}
	deviance = -2 * deviance;
}

