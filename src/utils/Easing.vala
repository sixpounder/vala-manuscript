public double ease_out_cubic (double t) {
    double p = t - 1;
    return p * p * p + 1;
}

