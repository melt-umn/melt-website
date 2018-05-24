#!groovy

library "github.com/melt-umn/jenkins-lib"

melt.setProperties(dummyNeedsToBeAtLeastOne: true)

melt.trynode('melt-website') {
  stage("Setup") {
    checkout scm
    sh "_scripts/ready-environment.sh"
  }
  stage("Generate") {
    sh "_scripts/build-silver-docs.sh"
  }
  stage("Build") {
    sh "_scripts/build-jekyll-site.sh"
  }
  if (env.BRANCH_NAME == 'master') {
    stage("Deploy") {
      sh "_scripts/deploy-site.sh"
    }
    // Once "deployed" a cron script will spot changes and copy to real site
  }
}

