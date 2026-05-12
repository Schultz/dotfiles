if test (uname) = Darwin
    # Herd injected PHP 8.3 configuration.
    set -gx HERD_PHP_83_INI_SCAN_DIR "$HOME/Library/Application Support/Herd/config/php/83/"

    # Herd injected PHP 8.4 configuration.
    set -gx HERD_PHP_84_INI_SCAN_DIR "$HOME/Library/Application Support/Herd/config/php/84/"

    # Herd injected PHP 8.5 configuration.
    set -gx HERD_PHP_85_INI_SCAN_DIR "$HOME/Library/Application Support/Herd/config/php/85/"
end
