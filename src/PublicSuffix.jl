module PublicSuffix

export Domain, tld_exists, public_suffix, PublicSuffixList
# TODO: puny code support
#export puny_encode, puny_decode
#include("punycode.jl")

type DPart
    name::String
    is_leaf::Bool
    is_exception::Bool
    children::Dict{String,DPart}
end

type PublicSuffixList
    _dtree::DPart

    function PublicSuffixList(list_file::String="")
        if isempty(list_file)
            list_file = joinpath(Pkg.dir("PublicSuffix"), "data", "effective_tld_names.dat")
        end

        root = DPart("", false, false, Dict{String,DPart}())
        open(list_file, "r") do f
            for line in readlines(f)
                (isempty(line) || beginswith(line, "//") || isspace(line[1])) && continue
                line = split(line)[1]
                add_node(line, root)
            end
        end
        new(root)
    end

    function add_node(fullname, root::DPart)
        is_exception = false
        if beginswith(fullname, '!')
            is_exception = true
            fullname = fullname[2:]
        end

        # parse fullname, hook into _dtree
        parts = split(fullname, '.')
        nparts = length(parts)
        node = root
        for idx in 1:nparts
            idx = nparts+1-idx
            part = parts[idx]
            if haskey(node.children, part)
                node = node.children[part]
            elseif !is_exception && haskey(node.children, "*")
                node = node.children["*"]
            else
                new_node = DPart(part, false, false, Dict{String,DPart}())
                node.children[part] = new_node
                node = new_node
            end
        end
        node.is_exception = is_exception
        node.is_leaf = true
        nothing
    end
end


type Domain
    full::String
    sub_domain::String
    public_suffix::String
    top_domain::String
    typ::Type    # valid types: IPv6, IPv4, Domain

    function Domain(domain::String, list::PublicSuffixList=_def_list)
        try
            ip = parseip(domain)
            # this is an ip
            return new(domain, "", "", "", typeof(ip))
        end
        domain = lowercase(domain)
        (beginswith(domain, '.') || endswith(domain, '.')) && error("invalid domain name $domain")

        parts = split(domain, '.')
        nparts = length(parts)
        node = list._dtree
        pub_nodes = String[]
        sub_nodes = String[]
        top_domain = String[]
        tld_mode = true
        is_exception = false

        for idx in 1:nparts
            idx = nparts+1-idx
            part = parts[idx]
            isempty(part) && error("invalid domain name $domain")

            if tld_mode && haskey(node.children, part)
                node = node.children[part]
                if node.is_exception
                    insert!(sub_nodes, 1, part)
                    tld_mode = false
                    is_exception = true
                else
                    insert!(pub_nodes, 1, part)
                end
                isempty(top_domain) && insert!(top_domain, 1, part)
            elseif tld_mode && haskey(node.children, "*")
                node = node.children["*"]
                insert!(pub_nodes, 1, part)
                tld_mode = false
            else
                insert!(sub_nodes, 1, part)
            end
        end
        isempty(sub_nodes) && error("incomplete domain name $domain")
        if isempty(top_domain)
            if length(sub_nodes) > 1
                insert!(pub_nodes, 1, pop!(sub_nodes))
                insert!(pub_nodes, 1, pop!(sub_nodes))
            end
        else
            insert!(pub_nodes, 1, is_exception ? sub_nodes[end] : pop!(sub_nodes))
        end
        new(domain, join(sub_nodes, '.'), join(pub_nodes, '.'), isempty(top_domain) ? "" : top_domain[1], Domain)
    end
end

_def_list = PublicSuffixList()

function tld_exists(tld::String; list::PublicSuffixList=_def_list)
    parts = split(tld, '.')
    nparts = length(parts)
    node = list._dtree
    for idx in 1:nparts
        idx = nparts+1-idx
        part = parts[idx]
        if haskey(node.children, part)
            node = node.children[part]
        elseif haskey(node.children, "*")
            node = node.children["*"]
        else
            return false
        end
    end
    return node.is_leaf 
end

public_suffix(domain::String; list::PublicSuffixList=_def_list) = return Domain(domain, list).public_suffix

end # module

