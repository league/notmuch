(use-modules
 ((guix licenses) #:prefix license:)
 (gnu packages bash)
 (gnu packages compression)
 (gnu packages emacs)
 (gnu packages glib)
 (gnu packages gnupg)
 (gnu packages mail)
 (gnu packages man)
 (gnu packages perl)
 (gnu packages pkg-config)
 (gnu packages python)
 (gnu packages python-xyz)
 (gnu packages samba)
 (gnu packages screen)
 (gnu packages search)
 (gnu packages sphinx)
 (gnu packages texinfo)
 (guix build utils)
 (guix build-system gnu)
 (guix git-download)
 (guix packages)
 (guix))

(define vcs-file?
  (or (git-predicate (current-source-directory))
      (const #t)))

(package
  (name "notmuch")
  (version "0.37")
  (source (local-file "." "notmuch-checkout"
                      #:recursive? #t
                      #:select? vcs-file?))
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
            (setenv "CONFIG_SHELL" (search-input-file inputs "/bin/sh"))
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
  (license license:gpl3+))
