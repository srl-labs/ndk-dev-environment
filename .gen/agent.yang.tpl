module {{ getenv "APPNAME" }} {
    yang-version 1.1;
    namespace "example.com/{{ getenv "APPNAME" }}";
    prefix "srl-labs-{{ getenv "APPNAME" }}";

    description
        "{{ getenv "APPNAME" }} YANG module";

    revision "{{ (time.Now).Local.Format "2006-01-02" }}" {
        description
            "initial release";
    }

    container {{ getenv "APPNAME" }} {
        leaf test {
            type string;
        }
    }
}