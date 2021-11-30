module {{ndkappname}} {
    yang-version 1.1;
    namespace "example.com/{{ndkappname}}";
    prefix "srl-labs-{{ndkappname}}";

    description
        "{{ndkappname}} YANG module";

    revision "2021-11-28" {
        description
            "initial release";
    }

    container {{ndkappname}} {
        leaf test {
            type string;
        }
    }
}