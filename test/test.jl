using PublicSuffix
using Base.Test

psl = PublicSuffixList()

test_tld_valid = ["com", "co.uk", "in", "org"]
test_tld_invalid = ["uk", "sdfdsfsdfdsf.in"]

for tld in test_tld_valid
    println("testing existing tld: $tld")
    @test tld_exists(tld)
end

for tld in test_tld_invalid
    println("testing non existing tld: $tld")
    @test !tld_exists(tld)
end

d = Domain("www.google.com")
@test d.typ == Domain
@test d.full == "www.google.com"
@test d.sub_domain == "www"
@test d.public_suffix == "google.com"
@test d.top_domain == "com"

d = Domain("192.168.1.1")
@test d.typ == IPv4
@test d.full == "192.168.1.1"
@test isempty(d.sub_domain)
@test isempty(d.public_suffix)
@test isempty(d.top_domain)

d = Domain("2001:0db8:85a3:0000:0000:8a2e:0370:7334")
@test d.typ == IPv6
@test d.full == "2001:0db8:85a3:0000:0000:8a2e:0370:7334"
@test isempty(d.sub_domain)
@test isempty(d.public_suffix)
@test isempty(d.top_domain)


