Canvas LMS
======

Canvas is a modern, open-source [LMS](https://en.wikipedia.org/wiki/Learning_management_system)
developed and maintained by [Instructure Inc.](https://www.instructure.com/) It is released under the
AGPLv3 license for use by anyone interested in learning more about or using
learning management systems.

[Please see our main wiki page for more information](http://github.com/instructure/canvas-lms/wiki)

Installation
=======

Detailed instructions for installation and configuration of Canvas are provided
on our wiki.

 * [Quick Start](http://github.com/instructure/canvas-lms/wiki/Quick-Start)
 * [Production Start](http://github.com/instructure/canvas-lms/wiki/Production-Start)

Capistrano
=======

This repository adds Capistrano to Canvas LMS to deploy the application and its updates.
Capistrano deployment is meant to be used with these [Ansible scripts](https://github.com/Kulgar/canvas-lms-ansible)

First deployment should be done with the `first_deploy` variable set, like this:

`cap environment deploy first_deploy=true`

Then all the updates should be done the usual `cap env deploy` way.
Look at the Ansible scripts Readme to get a detailed process about how to deploy your first Canvas LMS version.

We also activated `config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'` in production.rb configuration file.

All changes (if any) in the Canvas LMS code are tagged with the following comment:
`# Custom - Config - Capistrano:`
