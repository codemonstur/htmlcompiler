package htmlcompiler.compilers;

import de.neuland.pug4j.PugEngine;
import de.neuland.pug4j.RenderContext;
import de.neuland.pug4j.template.FileTemplateLoader;
import htmlcompiler.pojos.error.InvalidTemplate;
import io.pebbletemplates.pebble.PebbleEngine;
import io.pebbletemplates.pebble.error.PebbleException;
import io.pebbletemplates.pebble.template.PebbleTemplate;

import java.io.StringWriter;
import java.nio.file.Paths;
import java.util.Collections;
import java.util.Map;

public enum TemplateEngines {;

    public interface HtmlTemplateEngine extends FileCompiler {
        default String outputExtension() {
            return ".html";
        }
    }

    /**
     * Creates a template engine that renders jade or pug templates using pug4j.
     *
     * @param rootPath the directory that template paths are resolved against
     * @param context the variables made available to the template
     * @param extension the template file extension, without the leading dot
     * @return a compiler that renders the template to HTML
     */
    public static HtmlTemplateEngine newPug4jEngine(final String rootPath, final Map<String, String> context
            , final String extension) {
        final var root = Paths.get(rootPath).toAbsolutePath().normalize();
        final var engine = PugEngine.builder()
                .templateLoader(new FileTemplateLoader(root, extension))
                .build();
        return file -> {
            final var templatePath = root.relativize(file.toAbsolutePath().normalize());
            final var template = engine.getTemplate(templatePath.toString());
            return engine.render(template, Collections.unmodifiableMap(context), RenderContext.defaults());
        };
    }

    public static HtmlTemplateEngine newPebbleEngine(final Map<String, String> context) {
        final PebbleEngine pebble = new PebbleEngine.Builder().build();
        return file -> {
            try {
                final PebbleTemplate template = pebble.getTemplate(file.toAbsolutePath().toString());
                try (final StringWriter writer = new StringWriter()) {
                    template.evaluate(writer, Collections.unmodifiableMap(context));
                    return writer.toString();
                }
            } catch (PebbleException e) {
                throw new InvalidTemplate(e);
            }
        };
    }

}
