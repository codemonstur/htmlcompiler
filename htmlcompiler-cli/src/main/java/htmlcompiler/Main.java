package htmlcompiler;

import bobthebuildtool.pojos.buildfile.Project;

import java.nio.file.Path;

public final class Main {;

    public static void main(final String[] args) throws Exception {
        final Project project = new Project(Path.of(".").toAbsolutePath(), Path.of("bobfile"));
        final String[] rest = args.length > 1 ? java.util.Arrays.copyOfRange(args, 1, args.length) : new String[0];
        if (args.length > 0 && "host".equalsIgnoreCase(args[0])) {
            BobPlugin.hostFrontend(project, System.getenv(), rest);
        } else if (args.length > 0 && "dependencies".equalsIgnoreCase(args[0])) {
            BobPlugin.checkDependencies(project, System.getenv(), rest);
        } else {
            final String[] compileArgs = args.length > 0 && "compile".equalsIgnoreCase(args[0]) ? rest : args;
            BobPlugin.compileHtml(project, System.getenv(), compileArgs);
        }
    }
}