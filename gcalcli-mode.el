;;; gcalcli-mode.el --- Simple emacs mode around gcalcli ;; -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(defgroup gcalcli-mode-group nil
  "Settings for gcalcli-mode."
  :group 'comm
  :prefix "gcalcli-mode")

(defcustom gcalcli-mode-calendar "" "Calendar to show."
  :type 'string
  :group 'gcalcli-mode-group)

(defcustom gcalcli-mode-days-to-show 1 "Days to show."
  :type 'integer
  :group 'gcalcli-mode-group)

(defvar gcalcli-mode--date nil "Date for the gcal mode.")

(defconst gcalcli-mode--seconds-per-day (* 24 60 60) "Seconds for one day.")

(defun gcalcli-mode--format-date (time)
  "Format TIME to something like 2018-07-12."
  (let ((parts (decode-time time)))
    (format "%d-%02d-%02d" (nth 5 parts) (nth 4 parts) (nth 3 parts))))

(require 'ansi-color)
(defun gcalcli-mode--fill-buffer(date)
  "Fill the current buffer with gcal for DATE."
  (if (string-equal gcalcli-mode-calendar "")
    (customize-variable 'gcalcli-mode-calendar)
    (progn
      (erase-buffer)
      (let* (
              (start date)
              (end (time-add date (* gcalcli-mode--seconds-per-day gcalcli-mode-days-to-show)))
              (command (format "gcalcli agenda --calendar=%s --military %s %s"
                         gcalcli-mode-calendar
                         (gcalcli-mode--format-date start)
                         (gcalcli-mode--format-date end))))
        (setq gcalcli-mode--date date)
        (insert (format "Today: %s\n" (gcalcli-mode--format-date (current-time))))
        (message (format "Running command: %s" command))
        (call-process "bash" nil '(t nil) t "-c" (format "export LANGUAGE=en_US.UTF-8; export LC_ALL=en_US.UTF-8; %s" command)))
      (ansi-color-apply-on-region (point-min) (point-max)))))

;;;###autoload
(defun gcal ()
  "Get todays calendar things."
  (interactive)
  (get-buffer-create " *gcal*")
  (switch-to-buffer " *gcal*")
  (gcalcli-mode)
  (gcalcli-mode--fill-buffer (current-time)))

(defvar gcalcli-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "q") (lambda()
                                (interactive)
                                (kill-buffer (current-buffer))))
    (define-key map (kbd "n") (lambda()
                                (interactive)
                                (gcalcli-mode--fill-buffer (time-add gcalcli-mode--date gcalcli-mode--seconds-per-day))))
    (define-key map (kbd "p") (lambda()
                                (interactive)
                                (gcalcli-mode--fill-buffer (time-subtract gcalcli-mode--date gcalcli-mode--seconds-per-day))))
    (define-key map (kbd "g") (lambda()
                                (interactive)
                                (gcalcli-mode--fill-buffer gcalcli-mode--date)))
    (define-key map (kbd "+") (lambda()
                                (interactive)
                                (message "more")
                                (customize-set-variable 'gcalcli-mode-days-to-show (1+ gcalcli-mode-days-to-show))
                                (gcalcli-mode--fill-buffer gcalcli-mode--date)))
    (define-key map (kbd "-") (lambda()
                                (interactive)
                                (if (> gcalcli-mode-days-to-show 1)
                                  (progn
                                    (message "less")
                                    (customize-set-variable 'gcalcli-mode-days-to-show (1- gcalcli-mode-days-to-show))
                                    (gcalcli-mode--fill-buffer gcalcli-mode--date)))))
    map)
  "Mode map for gcal mode.")

(define-derived-mode gcalcli-mode text-mode "GCalCli"
  "Major mode for looking through your Google Calendar.")

(provide 'gcalcli-mode)
;;; gcalcli-mode.el ends here
