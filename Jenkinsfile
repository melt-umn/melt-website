#!groovy

library "github.com/melt-umn/jenkins-lib"

melt.setProperties(dummyNeedsToBeAtLeastOne: true)

melt.trynode('melt-website') {
  stage("Setup") {
    checkout scm
    sh "./setup-build-env"
  }
  stage("FetchDocs") {
    sh "./fetch-docs"
  }
  stage("Build") {
    sh "./build-site"
  }
  if (env.BRANCH_NAME == 'master') {
    stage("Deploy") {
      sh "./deploy-site"
    }
    // Once "deployed" a cron script will spot changes and copy to real site
  }
}

