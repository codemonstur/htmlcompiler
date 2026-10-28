package htmlcompiler.pojos.library;

public record LibraryKey(String name, String version, String type) {

    public static LibraryKey toLibraryKey(final LibraryRecord record) {
        return new LibraryKey(record.name(), record.version(), record.type());
    }
}
