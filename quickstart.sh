#!/bin/bash

DEFAULT_OPT_TAGS="untagged,provision,environment,undercloud-scripts,overcloud-scripts"

: ${OPT_BOOTSTRAP:=0}
: ${OPT_SYSTEM_PACKAGES:=0}
: ${OPT_TAGS:=$DEFAULT_OPT_TAGS}
: ${REQUIREMENTS:=requirements.txt}

install_deps () {
    yum -y install \
        /usr/bin/git \
        /usr/bin/virtualenv \
        gcc \
        libyaml \
        libselinux-python \
        libffi-devel \
        openssl-devel
}


print_logo () {

if [ `tput cols` -lt 105 ]; then

cat <<EOBANNER
----------------------------------------------------------------------------
|                                ,   .   ,                                 |
|                                )-_'''_-(                                 |
|                               ./ o\ /o \.                                |
|                              . \__/ \__/ .                               |
|                              ...   V   ...                               |
|                              ... - - - ...                               |
|                               .   - -   .                                |
|                                \`-.....-´                                 |
|   ____         ____      ____        _      _        _             _     |
|  / __ \       / __ \    / __ \      (_)    | |      | |           | |    |
| | |  | | ___ | |  | |  | |  | |_   _ _  ___| | _____| |_ __ _ _ __| |_   |
| | |  | |/ _ \| |  | |  | |  | | | | | |/ __| |/ / __| __/ _\` | '__| __|  |
| | |__| | |_| | |__| |  | |__| | |_| | | (__|   <\__ \ |_|(_| | |  | |_   |
|  \____/ \___/ \____/    \___\_\\\__,_|_|\___|_|\_\___/\__\__,_|_|   \__|  |
|                                                                          |
|                                                                          |
----------------------------------------------------------------------------


EOBANNER

else

cat <<EOBANNER
-------------------------------------------------------------------------------------------------------
|     ,   .   ,   _______   _       _       ____      ____        _      _        _             _     |
|     )-_'''_-(  |__   __| (_)     | |     / __ \    / __ \      (_)    | |      | |           | |    |
|    ./ o\ /o \.    | |_ __ _ _ __ | | ___| |  | |  | |  | |_   _ _  ___| | _____| |_ __ _ _ __| |_   |
|   . \__/ \__/ .   | | '__| | '_ \| |/ _ \ |  | |  | |  | | | | | |/ __| |/ / __| __/ _\` | '__| __|  |
|   ...   V   ...   | | |  | | |_) | |  __/ |__| |  | |__| | |_| | | (__|   <\__ \ |_|(_| | |  | |_   |
|   ... - - - ...   |_|_|  |_| .__/|_|\___|\____/    \___\_\\\__,_|_|\___|_|\_\___/\__\__,_|_|   \__|  |
|    .   - -   .             | |                                                                      |
|     \`-.....-´              |_|                                                                      |
-------------------------------------------------------------------------------------------------------


EOBANNER

fi
}

# This creates a Python virtual environment and installs
# tripleo-quickstart into that environment.  It only runs if
# the local working directory does not exist, or if explicitly
# requested via --bootstrap.
bootstrap () {
    (   # run in a subshell so that we can 'set -e' without aborting
        # the main script immediately (because we want to clean up
        # on failure).

    set -e

    virtualenv $( [ "$OPT_SYSTEM_PACKAGES" = 1 ] && printf -- "--system-site-packages\n" ) $OPT_WORKDIR
    . $OPT_WORKDIR/bin/activate

    echo "source $OPT_WORKDIR/bin/activate"
    source $OPT_WORKDIR/bin/activate
    python setup.py install
    pip install -r $REQUIREMENTS

    )
}

usage () {
    echo "$0: usage: $0 [options] virthost [release]"
    echo "$0: usage: sudo $0 --install-deps"
    echo "$0: options:"
    echo "    -s, --system-site-packages                Use system site packages"
    echo "    -v, --ansible-debug                       Invoke Ansible with -vvvv"
    echo "    -b, --bootstrap                           default: true, create python virtual environment and setup"
    echo "    -w, --working-dir <directory>             default: $PWD/.quickstart, the directory from which ansible reads the playbook and config"
    echo "    -p, --playbook <playbook name>            default: 'tripleo', the playbook that will be invoked"
    echo "    -z, --requirements <requirements file>    default: 'requirements.txt', the requirments file"
    echo "    -r, --release <release>                   default: 'mitaka', the release of tripleo to deploy"
    echo "    -t, --tags <tag1>[,<tag2>,...]                default: untagged,provision,environment,undercloud-scripts,overcloud-scripts, ansible tags"
    echo "    --skip-tags <tag1>,[<tag2>,...]           default: 'none', ansible skip-tags"
    echo "    -c, --config <file>                           default: '$OPT_WORKDIR/config/minimal', Just enough for a minimal tripleo install"
    echo "    --print-logo                              Print the tripleo logo, WOOT"

}

while [ "x$1" != "x" ]; do

    case "$1" in
        --install-deps)
            OPT_INSTALL_DEPS=1
            ;;

        --playbook|-p)
            PLAYBOOK=$2
            shift
            ;;

        --requirements|-z)
            REQUIREMENTS=$2
            shift
            ;;

        --system-site-packages|-s)
            OPT_SYSTEM_PACKAGES=1
            ;;

        --release|-r)
            RELEASE=$2
            shift
            ;;

        --bootstrap|-b)
            OPT_BOOTSTRAP=1
            ;;

        --ansible-debug|-v)
            OPT_DEBUG_ANSIBLE=1
            ;;

        --working-dir|-w)
            OPT_WORKDIR=$2
            shift
            ;;

        --tags|-t)
            OPT_TAGS=$2
            shift
            ;;

        --skip-tags)
            OPT_SKIP_TAGS=$2
            shift
            ;;

        --config|-c)
            OPT_CONFIG=$2
            shift
            ;;

        --help|-h)
            usage
            exit
            ;;

        # developer options

        --gerrit|-g)
            OPT_GERRIT=$2
            OPT_BOOTSTRAP=1
            shift
            ;;

        --no-clone|-n)
            OPT_NO_CLONE=1
            ;;

        --print-logo|-pl)
            PRINT_LOGO=1
            ;;

        --) shift
            break
            ;;

        -*) echo "ERROR: unknown option: $1" >&2
            usage >&2
            exit 2
            ;;

        *)    break
            ;;
    esac

    shift
done

if [ "$PRINT_LOGO" = 1 ]; then
    print_logo
    echo "..."
    echo "Nothing more to do"
    exit 1
fi

# Set this default after option processing, because the default depends
# on another option.

if [ "$OPT_INSTALL_DEPS" = 1 ]; then
    echo "NOTICE: installing dependencies"
    install_deps
    exit $?
fi

if [ "$#" -lt 1 ]; then
    echo "ERROR: You must specify a target machine." >&2
    usage >&2
    exit 2
fi

if [ "$#" -gt 2 ]; then
    usage >&2
    exit 2
fi

VIRTHOST=$1
if [[ $VIRTHOST == "localhost" ]];then
    echo "Detected localhost, will use 127.0.0.2 as localhost is reserved by ansible"
    export VIRTHOST=127.0.0.2;
fi

if [ -z "$RELEASE" ]; then
    RELEASE=mitaka
fi

if [ -z "$PLAYBOOK" ]; then
    PLAYBOOK=quickstart
fi

#Detect and setup directory
if [[ $PWD == *"tripleo-quickstart" ]]; then
    echo " I see you have already cloned the quickstart repo"
else
    echo "The tripleo-quickstart repo has not been detected in the path"
    if [ "$OPT_NO_CLONE" != 1 ]; then
        if ! [ -d "tripleo-quickstart" ]; then
            echo "Cloning tripleo-quickstart repository..."
            git clone https://github.com/weshayutin/tripleo-quickstart-1.git \
                tripleo-quickstart
        fi

        cd $PWD/tripleo-quickstart
        if [ -n "$OPT_GERRIT" ]; then
            git review -d "$OPT_GERRIT"
        else
            git remote update
            git checkout --quiet origin/master
        fi
    fi

fi
OPT_WORKDIR=$PWD/.quickstart
echo "Local Working Directory $OPT_WORKDIR"


print_logo
echo "Installing OpenStack ${RELEASE:+"$RELEASE "}on host $VIRTHOST"
echo "Using directory $OPT_WORKDIR for a local working directory"

if [ "$OPT_BOOTSTRAP" = 1 ] || ! [ -f "$OPT_WORKDIR/bin/activate" ]; then
    bootstrap

    if [ $? -ne 0 ]; then
        echo "ERROR: bootstrap failed; removing $OPT_WORKDIR"
    echo "       try "sudo $0 --install-deps" to install requirements"
        rm -rf $OPT_WORKDIR
        exit 1
    fi
fi


set -ex

export ANSIBLE_INVENTORY=$OPT_WORKDIR/hosts

if [ "$VIRTHOST" = "localhost" ]; then
    echo "$0: WARNING: VIRTHOST == localhost; skipping provisioning" >&2
    OPT_SKIP_TAGS="${OPT_SKIP_TAGS:+$OPT_SKIP_TAGS,}provision"

    echo "[virthost]" > $ANSIBLE_INVENTORY
    echo "localhost ansible_connection=local" >> $ANSIBLE_INVENTORY
fi

if [ "$OPT_DEBUG_ANSIBLE" = 1 ]; then
    VERBOSITY=vvvv
else
    VERBOSITY=vv
fi

# source the virtual environment
source $OPT_WORKDIR/bin/activate

# set a default topologyconfiguration if required
: ${OPT_CONFIG:=$OPT_WORKDIR/config/general_config/minimal.yml}

# use exported ansible variables
source $OPT_WORKDIR/../ansible_env
env | grep ANSIBLE
echo " "; echo " "

echo "Installing OpenStack ${RELEASE:+"$RELEASE "}on host $VIRTHOST"
echo "Executing Ansible..."
echo ""
set -x

ansible-playbook -$VERBOSITY $OPT_WORKDIR/playbooks/$PLAYBOOK.yml \
    -e ansible_python_interpreter=/usr/bin/python \
    -e @$OPT_WORKDIR/config/release/$RELEASE.yml \
    -e local_working_dir=$OPT_WORKDIR \
    -e virthost=$VIRTHOST \
    -e @$OPT_CONFIG \
    ${OPT_TAGS:+-t $OPT_TAGS} \
    ${OPT_SKIP_TAGS:+--skip-tags $OPT_SKIP_TAGS}

# We only print out further usage instructions when using the default
# tags, since this is for new users (and not even applicable to some tags).

set +x

if [ $OPT_TAGS = $DEFAULT_OPT_TAGS ] ; then

cat <<EOF
##################################
Virtual Environment Setup Complete
##################################

Access the undercloud by:

    ssh -F $OPT_WORKDIR/ssh.config.ansible undercloud

There are scripts in the home directory to continue the deploy:

    undercloud-install.sh will run the undercloud install
    undercloud-post-install.sh will perform all pre-deploy steps
    overcloud-deploy.sh will deploy the overcloud
    overcloud-deploy-post.sh will do any post-deploy configuration
    overcloud-validate.sh will run post-deploy validation

Alternatively, you can ignore these scripts and follow the upstream docs:

First:

    openstack undercloud install
    source stackrc

Then continue with the instructions (limit content using dropdown on the left):

    http://ow.ly/Ze8nK

##################################
Virtual Environment Setup Complete
##################################
EOF
if [ $OPT_TAGS != $DEFAULT_OPT_TAGS ] ; then

cat <<EOF
##################################
Virtual Environment Setup Complete
##################################

Logs of the deployment are available on the undercloud node in /home/stack

Access the undercloud by:

    ssh -F $OPT_WORKDIR/ssh.config.ansible undercloud
EOF
fi



