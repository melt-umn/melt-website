#!groovy

library "github.com/melt-umn/jenkins-lib"

melt.setProperties(dummyNeedsToBeAtLeastOne: true)

node {
try {
  stage("Setup") {
    checkout scm
    sh "jenkins/ready-environment.sh"
  }
  stage("Generate") {
    sh "jenkins/build-silver-docs.sh"
  }
  stage("Build") {
    sh "jenkins/build-jekyll-site.sh"
  }
  if (env.BRANCH_NAME == 'master') {
    stage("Deploy") {
      sh "jenkins/deploy-site.sh"
    }
  }
} catch(e) {
  melt.handle(e)
} finally {
  melt.notify(job: "melt-website")
}
} // node

