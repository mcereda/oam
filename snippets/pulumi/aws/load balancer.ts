/*
 * aws.lb.LoadBalancer
 * aws.alb.TargetGroup
 * aws.route53.Record (for cert) --- aws.acm.Certificate --- aws.route53.Record (for validation)
 * [aws.lb.LoadBalancer, aws.acm.Certificate, aws.alb.TargetGroup] --- aws.alb.Listener
 */
