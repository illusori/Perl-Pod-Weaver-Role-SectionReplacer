package Pod::Weaver::Role::SectionReplacer;

# ABSTRACT: a Pod::Weaver section that will replace itself in the original document

use Moose::Role;
with 'Pod::Weaver::Role::Transformer';

use Moose::Autobox;
use Pod::Elemental::Selectors -all;

our $VERSION = '0.99_01';

has original_section => (
  is  => 'rw',
);

has section_name => (
  is  => 'ro',
  isa => 'Str',
  default => sub { $_[ 0 ]->default_section_name },
);

requires 'default_section_name';

has section_aliases => (
  is  => 'ro',
  isa => 'ArrayRef[Str]',
  default => sub { $_[ 0 ]->default_section_aliases },
);

sub default_section_aliases { []; }

sub transform_document {
  my ( $self, $document ) = @_;

  #  Build a selector for a =head1 with the correct content text.
  my $command_selector = s_command('head1');
  my $aliases = [ $self->section_name, @{ $self->section_aliases } ];
  my $named_selector = sub {
      my ( $node ) = @_;

      my $content = $node->content;
      $content =~ s/^\s+//;
      $content =~ s/\s+$//;

      return( $command_selector->( $_[ 0 ] ) &&
        $aliases->any() eq $content );
    };

  return unless $document->children->grep($named_selector)->length;

  #  Take the first matching section found...
  $self->original_section($document->children->grep($named_selector)->first);

  #  ...and prune it from the document.
  my $in_node = $document->children;
  for ( my $i = 0; $i <= $#{ $in_node }; $i++ ) {
    next unless $in_node->[ $i ] == $self->original_section;

    splice @{ $in_node }, $i, 1;
    last;
  }
};

sub mvp_aliases { { section_alias => 'section_aliases', }; }
sub mvp_multivalue_args { ( 'section_aliases', ); }

no Moose::Role;
1;

__END__

=pod

=head1 NAME

Pod::Weaver::Role::SectionReplacer - a Pod::Weaver section that will replace itself in the original document

=head1 VERSION

version 0.99_01

=head1 SYNOPSIS

A role for L<Pod::Weaver> plugins, allowing them to replace a named
section of the input document rather than appending a potentially
duplicate section.

=head1 NAME

Pod::Weaver::Role::SectionReplacer - a Pod::Weaver section that will replace itself in the original document

=head1 IMPLEMENTING

This role is used by plugins that will find an existing section in the input
document.
It will prune the existing section from the input document and make it
available under C<original_section> method:

  $section_plugin->original_section();

The plugin could then choose to keep the original, by inserting it
into the document again, or to write something new instead, or some
combination of the two.

The plugin must provide a method, C<default_section_name> which will return
the default name of the section, as used in the =head1 line, this is
available for later query via the C<section_name> accessor:

  $section_plugin->section_name

It is recommended that you use this accessor for generating the section
title rather than hard-coding a value directly, because it then allows
the end-user to configure the section name in their weaver.ini, eg:

  [ReplaceLegal]
  section_name = MY CUSTOMIZED LICENSE AND COPYRIGHT HEADING

The plugin may also provide a C<default_section_aliases> method, which
should return an arrayref of alternative section names to match.
Like C<section_name> this allows the end-user to override the default
section aliases:

  [ReplaceLegal]
  section_name  = MY CUSTOMIZED LICENSE AND COPYRIGHT HEADING
  section_alias = LICENSE AND COPYRIGHT
  section_alias = COPYRIGHT AND LICENSE
  section_alias = LICENCE AND COPYRIGHT
  section_alias = COPYRIGHT AND LICENCE

=head1 AUTHOR

Sam Graham <libpod-weaver-role-sectionreplacer-perl@illusori.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Sam Graham <libpod-weaver-role-sectionreplacer-perl@illusori.co.uk>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
