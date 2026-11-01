package htmlcompiler.pojos.library;

import java.util.List;

public record LibraryDescription(String tagName, List<Attribute> attributes) {

    public static LibraryDescription toLibraryDescription(final LibraryRecord record) {
        return new LibraryDescription(record.tagName(), record.attributes());
    }

}
