Name:           perl-perfSONAR_PS-Base
Version:        0.09
Release:        1%{?dist}
Summary:        perfSONAR_PS::Base Perl module
License:        distributable, see LICENSE
Group:          Development/Libraries
URL:            http://search.cpan.org/dist/perfSONAR_PS-Base/
Source0:        http://www.cpan.org/modules/by-module/perfSONAR_PS/perfSONAR_PS-Base-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
Requires:       perl(Data::Compare) >= 0.09
Requires:       perl(Data::Stack) >= 0.01
Requires:       perl(Error)
Requires:       perl(LWP::UserAgent) >= 2.032
Requires:       perl(Log::Log4perl) >= 1
Requires:       perl(Params::Validate) >= 0.7
Requires:       perl(XML::LibXML) >= 1.58
Requires:       perl(version)
Requires:       perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))

%description
perfSONAR_PS::Base contains a set modules used by the various perfSONAR_PS
clients and services.

%prep
%setup -q -n perfSONAR_PS-Base-%{version}

%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}

%install
rm -rf $RPM_BUILD_ROOT

make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT

find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} \;
find $RPM_BUILD_ROOT -type d -depth -exec rmdir {} 2>/dev/null \;

chmod -R u+rwX,go+rX,go-w $RPM_BUILD_ROOT/*

%check
make test

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%doc Changes LICENSE README perl-perfSONAR_PS-Base.spec
%{perl_vendorlib}/*
%{_mandir}/man3/*

%changelog
* Thu Mar 27 2008 aaron@internet2.edu 0.09-1
- Specfile autogenerated.