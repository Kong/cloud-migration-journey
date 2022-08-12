FROM registry.redhat.io/jboss-eap-7/eap74-openjdk11-openshift-rhel8:7.4.5-5
COPY ./target/monolith.war $JBOSS_HOME/standalone/deployments/

# User root to modify war owners
USER root

# Modify owners war
RUN chown jboss:jboss $JBOSS_HOME

USER jboss