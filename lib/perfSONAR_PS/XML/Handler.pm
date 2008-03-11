#!/usr/bin/perl -w

package perfSONAR_PS::XML::Handler;

#use Data::Stack;
use perfSONAR_PS::XML::Element;
use Carp qw( croak );
@ISA = ('Exporter');
@EXPORT = ();
           
our $VERSION = 0.08;

sub new {
  my ($package, $stack) = @_;   
  my %hash = ();
  $hash{"FUNCTION"} = "\"new\"";
  $hash{"FILENAME"} = "Handler";
  if(defined $stack) {
    $hash{"STACK"} = $stack;
  }
  else {
    croak($self->{FILENAME}.":\tStack argument required in ".$self->{FUNCTION});
  }  
  bless \%hash => $package;
}


sub start_document {
  my ($self) = @_;
  $self->{FUNCTION} = "\"start_document\"";

  # unused for now
}


sub end_document {
  my ($self) = @_;
  $self->{FUNCTION} = "\"end_document\"";

  # unused for now
}


sub start_element {
  my ($self, $element) = @_;
  $self->{FUNCTION} = "\"start_element\"";
  if(defined $element) {
    my $newElement = new perfSONAR_PS::XML::Element();

    if(defined $self->{NSDEPTH}{$element->{Prefix}}) {
      $self->{NSDEPTH}{$element->{Prefix}}++;  
    }
    else {
      $self->{NSDEPTH}{$element->{Prefix}} = 1;
      $newElement->addAttribute("xmlns:".$element->{Prefix}, $element->{NamespaceURI});    
    }
    
    my %attrs = %{$element->{Attributes}};
    foreach $a (keys %attrs) {
      if($attrs{$a}{Prefix} ne "xmlns" and $attrs{$a}{NamespaceURI} ne "http://www.w3.org/2000/xmlns/") {
        $newElement->addAttribute($attrs{$a}{Name}, $attrs{$a}{Value});               
      }
    }
  
    $newElement->setParent($self->{STACK}->peek());
    if($newElement->getAttributeByName("id") eq "") {
      $newElement->setID(genuid());
    }
    else {
      $newElement->setID($newElement->getAttributeByName("id"));
    }    
    $newElement->setPrefix($element->{Prefix});
    $newElement->setURI($element->{NamespaceURI});
    $newElement->setLocalName($element->{LocalName});
    $newElement->setQName($element->{Name});  
  
    $self->{STACK}->peek()->addChild($newElement);
    $self->{STACK}->push($newElement);   
  }
  else {
    croak($self->{FILENAME}.":\tMissing argument to ".$self->{FUNCTION});
  }
  return;       
}


sub end_element {
  my ($self, $element) = @_;
  $self->{FUNCTION} = "\"end_element\"";
  if(defined $element) {
    if($self->{STACK}->empty()) {
      croak($self->{FILENAME}.":\tPop on empty stack in ".$self->{FUNCTION});
    }
    else {
      my $top = $self->{STACK}->pop(); 
    }
  
    $self->{NSDEPTH}{$element->{Prefix}}--;
    if($self->{NSDEPTH}{$element->{Prefix}} == 0) {
      undef $self->{NSDEPTH}{$element->{Prefix}};
    }
  }
  else {
    croak($self->{FILENAME}.":\tMissing argument to ".$self->{FUNCTION});
  }
  return;  
}


sub characters {
  my ($self, $characters) = @_;
  $self->{FUNCTION} = "\"characters\"";
  if(defined $characters) {
    my $text = $characters->{Data};
    $text =~ s/^\s*//;
    $text =~ s/\s*$//;
    return '' unless $text;
    $self->{STACK}->peek()->setValue($text);
  }
  else {
    croak($self->{FILENAME}.":\tMissing argument to ".$self->{FUNCTION});
  }
  return;
}


sub genuid {
  my ($r) = int( rand( 16777216 ) );
  return ( $r + 1048576 );
}


1;


__END__
=head1 NAME

Handler - A module that acts as an XML element handler for a SAX parser 
(Specifically from the XML::SAX family).  

=head1 DESCRIPTION

The job of a handler is to listen for SAX events, and act on the 
information that is passed from the parsing system above.  The particular 
handler relies on objects of type 'Element' for storage, and requires 
the use of an external stack to manage intereactions of these objects.  

=head1 SYNOPSIS
 
    use XML::SAX::ParserFactory;
    use Data::Stack;
    use Handler;
    use Element;

    my $file = "store.xml"

    # set up the stack
    my $stack = new Data::Stack();
    my $sentinal = new Element();
    $sentinal->setParent($sentinal);
    $stack->push($sentinal);

    # parse with a custom handler
    my $handler = Handler->new($stack);
    my $p = XML::SAX::ParserFactory->parser(Handler => $handler);
    $p->parse_uri($file);

    #get the object of the 'root' element
    my $element = $stack->peek()->getChildByIndex(0);

    #print the element
    $element->print();

=head1 DETAILS

This code is dependent upon the output of the underlying SAX system.  There are
many SAX parsers, many of which have different features.  We have found that 
the XML::SAX library offers more features than others (such as XML::Parser::SAX).
Using this handler with a different library may result in unexpected behavior.

=head1 API

The API is not meant to be called by the user, and all (with the exception of
one) functions represent events that will be generated by the SAX parser.  

=head2 new($package, $stack)

The '\%conf' hash contains arguments supplied to the service by the user (such as log files). 
Creates a new handler object, a external stack (of type Data::Stack) MUST
be passed in.  This stack is the only way to access the finished element
tree after parsing has finished.  

=head2 start_document($self)

This event indicates the document has started parsing, it is not used in 
this handler.  

=head2 end_document($self)

This event indicates the document is done parsing, it is not used in this
handler.  

=head2 start_element($self, $element)

When an element is started, we allocate a new element object and populate
it with the necessary information:

  Local Name - Non-prefixed name of the element
  Prefix - Prefix that maps to a namespace URI.
  Namespace URI - URI that indicates an element's membership.
  Qualified Name - Prefix + Local Name of an element.
  Attributes - name/value pairs of information in the element.
  Children - Array of child elements that are 'within' this element.
  Parent - The element that the 'parent' (directly above) this element.
  
Additionally, we keep track of namespace nesting to ensure that namespaces
are only declared once per scope.  The element, once populated, is pushed on
to the stack, and the previous top of the stack is marked as the 'parent' of
this element.  

=head2 end_element($self, $element)

When the end of an element is seen we must pop the stack (to indicate that
this element has ended) and expose the next 'parent' element.  We also update
the namespace counter.  

=head2 characters($self, $characters)

If bare characters are discovered in an XML document, the 'characters' event 
is triggered.  Most times this event may indicate whitespace, and a simple 
regex can be used to exit if this is the case.  When the event is meaningful, 
we wish to pass the seen value back to the element that resides on the top of
the stack by populating it's 'Value' field.  

=head2 genuid()

Generates a random number.  This auxilary function is used to generate
an ID value for elements who are not assigned one.  

=head1 SEE ALSO

L<Element>, L<XML::SAX>, L<Data::Stack>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS 
  
Questions and comments can be directed to the author, or the mailing list. 

=head1 AUTHOR

Jason Zurawski, E<lt>zurawski@eecis.udel.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Jason Zurawski

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.
