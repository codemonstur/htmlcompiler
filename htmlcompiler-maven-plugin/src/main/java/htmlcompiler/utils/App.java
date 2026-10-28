package htmlcompiler.utils;

import org.apache.maven.plugin.AbstractMojo;
import org.apache.maven.plugin.MojoFailureException;

public enum App {;

    public interface MavenTask {
        void build(Logger log) throws Exception;
    }

    public static void buildMavenTask(final AbstractMojo mojo, final MavenTask task) throws MojoFailureException {
        try {
            final Logger log = Logger.newLogger(mojo.getLog()::info, mojo.getLog()::warn, mojo.getLog()::error);
            task.build(log);
        } catch (final Exception e) {
            throw new MojoFailureException(e.getMessage(), e);
        }
    }
}
