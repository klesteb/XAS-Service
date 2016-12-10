package XAS::Apps::Service::Processor;

use Template;
use JSON::XS;
use Web::Machine;
use Plack::Builder;
use Authen::Simple;
use Plack::App::File;
use Plack::App::URLMap;
use XAS::Service::Server;

use XAS::Class
  version    => '0.01',
  base       => 'XAS::Lib::App::Service',
  mixin      => 'XAS::Lib::Mixins::Configs',
  utils      => 'load_module trim',
  filesystem => 'File Dir',
  accessors  => 'cfg',
  vars => {
      SERVICE_NAME         => 'XAS_TESTD',
      SERVICE_DISPLAY_NAME => 'XAS test micro service',
      SERVICE_DESCRIPTION  => 'This process is a test micro service'
  }
;

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub build_routes {
    my $self        = shift;
    my $urlmap      = shift;
    my $base        = shift;
    my $template    = shift;
    my $json        = shift;
    my $name        = shift;
    my $description = shift;
    my $authen      = shift;

    $$urlmap->mount('/' => Web::Machine->new(
        resource => 'XAS::Service::Resource',
        resource_args => [
            alias           => 'root',
            template        => $template,
            json            => $json,
            app_name        => $name,
            app_description => $description,
            authenticator   => $authen,
        ] )
    );

}

sub build_static {
    my $self = shift;
    my $root = shift;

    my $urlmap = Plack::App::URLMap->new();

    # static routes

    $urlmap->mount('/js' => Plack::App::File->new(
        root => Dir($root, '/js')->path )
    );

    $urlmap->mount('/css' => Plack::App::File->new(
        root => Dir($root, '/css')->path )
    );

    $urlmap->mount('/yaml' => Plack::App::File->new(
        root => Dir($root, '/yaml/yaml')->path )
    );

    return $urlmap;

}

sub build_authen {
    my $self = shift;

    my @parameters;
    my $authen = $self->cfg->val('authenticator', 'name', 'Authen::Simple::PAM');
    my $params = $self->cfg->val('authenticator', 'parameters', "service = 'login'");

    foreach my $p (split(',', $params)) {

        my ($key, $value) = split('=', $p);

        push(@parameters, trim($key));
        push(@parameters, trim($value));

    }

    load_module($authen);

    return Authen::Simple->new( $authen->new(@parameters) );

}

sub build_app {
    my $self   = shift;

    # define base, name and description

    my @paths;
    my $path = Dir($self->env->lib, 'web', 'root');
    my $root = Dir($self->cfg->val('app', 'root', $path->path));
    my $base = Dir($self->cfg->val('app', 'base', $path->path));
    my $name = $self->cfg->val('app', 'name', 'WEB Services');
    my $description = $self->cfg->val('app', 'description', 'Test api using RESTFUL HAL-JSON');

    push(@paths, $base->path);
    push(@paths, $root->path) unless ($base eq $root);

    # Template config

    my $config = {
        INCLUDE_PATH => \@paths,   # or list ref
        INTERPOLATE  => 1,         # expand "$var" in plain text
    };

    # create various objects

    my $template = Template->new($config);
    my $json     = JSON::XS->new->utf8();
    my $authen   = $self->build_authen;

    # allow variables with preceeding _

    $Template::Stash::PRIVATE = undef;

    # handlers, using URLMap for routing

    my $builder = Plack::Builder->new();
    my $urlmap  = $self->build_static($root);

    $self->build_routes(\$urlmap, $base, $template, $json, $name, $description, $authen);

    return $builder->to_app($urlmap->to_app);

}

sub setup {
    my $self = shift;

    my $interface = XAS::Service::Server->new(
        -alias   => 'interface',
        -port    => $self->cfg->val('system', 'port', 9507),
        -address => $self->cfg->val('system', 'address', 'localhost'),
        -app     => $self->build_app,
    );

    $self->service->register('interface');

}

sub main {
    my $self = shift;

    $self->log->info_msg('startup');

    $self->setup();
    $self->service->run();

    $self->log->info_msg('shutdown');

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    $self->load_config();

    return $self;

}

1;

__END__

=head1 NAME

XAS::Apps::Service::Testd - This module provides a test micro service

=head1 SYNOPSIS

 use XAS::Apps::Service::Testd;

 my $app = XAS::Apps::Service::Testd->new();

 exit $app->run();

=head1 DESCRIPTION

This module module provides a test micro service.

=head1 CONFIGURATION

The configuration file follows the familiar Windows .ini format. It contains
following stanzas.

 [system]
 port = 9507
 address = 127.0.0.1

This stanza defines the network interface. By default the process listens on
port 9507 on the 127.0.0.1 network.

 [app]
 base = /var/lib/xas/web
 name = My Great service
 description = This is a really great service

This stanza defines where the root directory for html assets are stored and
the name and description of the micro service.

=head1 EXAMPLE

 [system]
 port = 9507
 address = 127.0.0.1

 [app]
 base = /var/lib/xas/web
 name = My Great service
 description = This is a really great service

=head1 SEE ALSO

=over 4

=item L<XAS::Service|XAS::Service>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2016 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
