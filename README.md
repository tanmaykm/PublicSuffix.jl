PublicSuffix.jl
===============

Julia Interface for working with the Public Suffix List at http://publicsuffix.org/.

## Type PublicSuffixList
Parses the public suffix data dump and represents the data as a tree to be used in other APIs.
A version of the file is bundled with the package, but the latest data is available online [here](http://publicsuffix.org/list/effective_tld_names.dat).

Constructors:

````
psl = PublicSuffixList()                    # use the bundled public suffix list data
psl = PublicSuffixList(list_file::String)   # use the data provided in list_file
````

## Type Domain
Represents an internet domain name as the following attributes:

- `full` : The full domain name as provided
- `sub_domain` : The sub\_domain part of the domain name
- `public_suffix` : The valid public suffix for the domain name
- `top_domain` : The top level domain for the domain name
- `typ` : Type of the input: `:IPv6`, `:IPv4`, `:Domain`. Attributes `sub_domain`, `public_suffix` and `top_domain` are valid only if type is `:Domain`.

Constructor: `Domain(domain::String, list::PublicSuffixList=_def_list)`


## Utility Functions
````
function tld_exists(tld::String; list::PublicSuffixList=_def_list)
    Check whether the specified top level domain is valid.

function public_suffix(domain::String; list::PublicSuffixList=_def_list)
    Returns the public siffix string for the given domain.
````

