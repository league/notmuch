(define-module (notmuch-packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages mail)
  #:use-module (gnu packages man)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages samba)
  #:use-module (gnu packages screen)
  #:use-module (gnu packages search)
  #:use-module (gnu packages sphinx)
  #:use-module (gnu packages texinfo)
  #:use-module (guix build utils)
  #:use-module (guix build-system gnu)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix))

(define-public notmuch-sort-fork
  (package
    (name "notmuch-sort-fork")
    (version "0.37")
    (source (local-file
	     "../.." "notmuch-checkout"
	     #:recursive? #t
	     #:select?
	     (or (git-predicate
		  (string-append (current-source-directory) "/../.."))
		 (const #t))))
    (build-system gnu-build-system)
    (arguments
     (list
      #:make-flags
      #~(list "V=1"                      ; verbose test output
              "NOTMUCH_TEST_TIMEOUT=1h") ; don't fail on slow machines
      #:phases
      #~(modify-phases %standard-phases
          (replace 'configure
            (lambda* (#:key inputs #:allow-other-keys)
              (setenv "CC" #$(cc-for-target))
              (setenv "CONFIG_SHELL"
		      (search-input-file inputs "/bin/sh"))
              (invoke "./configure"
                      (string-append "--prefix=" #$output)
                      "--without-emacs")))
          (add-before 'check 'prepare-test-environment
            (lambda* (#:key inputs #:allow-other-keys)
              (setenv "TEST_CC" #$(cc-for-target))
	      (setenv "NOTMUCH_SKIP_TESTS"
		      (string-join '("setup.2"
				     "emacs-reply"
				     "emacs-dont-reply-names")))
              ;; Patch various inline shell invocations.
              (let ((sh (search-input-file inputs "/bin/sh")))
		(substitute* (find-files "test" "\\.sh$")
                  (("/bin/sh") sh))))))))
    (native-inputs
     (list bash-completion
           pkg-config
           python
           python-docutils
           python-sphinx
           texinfo
           ;; The following are required for tests only.
           emacs-no-x	; -minimal lacks libxml, needed for some tests
           dtach
           gnupg
           man-db
           perl))
    (inputs
     (list glib gmime talloc xapian zlib))
    (home-page "https://notmuchmail.org/")
    (synopsis "Thread-based email index, search, and tagging")
    (description
     "Notmuch is a command-line based program for indexing, searching, read-
ing, and tagging large collections of email messages.")
    (license license:gpl3+)))

notmuch-sort-fork
