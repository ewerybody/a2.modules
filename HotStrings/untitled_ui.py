# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file 'C:\Users\eRiC\io\code\a2\modules\a2.modules\HotStrings\untitled.ui'
#
# Created: Mon Oct 31 23:28:41 2016
#      by: pyside-uic 0.2.15 running on PySide 1.2.2
#
# WARNING! All changes made in this file will be lost!

from PySide import QtCore, QtGui

class Ui_Form(object):
    def setupUi(self, Form):
        Form.setObjectName("Form")
        Form.resize(848, 822)
        self.formLayout = QtGui.QFormLayout(Form)
        self.formLayout.setFieldGrowthPolicy(QtGui.QFormLayout.AllNonFixedFieldsGrow)
        self.formLayout.setObjectName("formLayout")
        self.plainTextEdit = QtGui.QPlainTextEdit(Form)
        self.plainTextEdit.setObjectName("plainTextEdit")
        self.formLayout.setWidget(0, QtGui.QFormLayout.SpanningRole, self.plainTextEdit)
        self.checkBox_2 = QtGui.QCheckBox(Form)
        self.checkBox_2.setObjectName("checkBox_2")
        self.formLayout.setWidget(1, QtGui.QFormLayout.LabelRole, self.checkBox_2)
        self.checkBox = QtGui.QCheckBox(Form)
        self.checkBox.setObjectName("checkBox")
        self.formLayout.setWidget(7, QtGui.QFormLayout.LabelRole, self.checkBox)
        self.checkBox_6 = QtGui.QCheckBox(Form)
        self.checkBox_6.setObjectName("checkBox_6")
        self.formLayout.setWidget(8, QtGui.QFormLayout.LabelRole, self.checkBox_6)
        self.checkBox_4 = QtGui.QCheckBox(Form)
        self.checkBox_4.setObjectName("checkBox_4")
        self.formLayout.setWidget(3, QtGui.QFormLayout.LabelRole, self.checkBox_4)
        self.checkBox_3 = QtGui.QCheckBox(Form)
        self.checkBox_3.setObjectName("checkBox_3")
        self.formLayout.setWidget(2, QtGui.QFormLayout.LabelRole, self.checkBox_3)
        self.checkBox_5 = QtGui.QCheckBox(Form)
        self.checkBox_5.setObjectName("checkBox_5")
        self.formLayout.setWidget(4, QtGui.QFormLayout.LabelRole, self.checkBox_5)
        self.checkBox_7 = QtGui.QCheckBox(Form)
        self.checkBox_7.setObjectName("checkBox_7")
        self.formLayout.setWidget(5, QtGui.QFormLayout.LabelRole, self.checkBox_7)
        self.checkBox_8 = QtGui.QCheckBox(Form)
        self.checkBox_8.setObjectName("checkBox_8")
        self.formLayout.setWidget(6, QtGui.QFormLayout.LabelRole, self.checkBox_8)
        self.comboBox = QtGui.QComboBox(Form)
        self.comboBox.setObjectName("comboBox")
        self.comboBox.addItem("")
        self.comboBox.addItem("")
        self.comboBox.addItem("")
        self.formLayout.setWidget(9, QtGui.QFormLayout.LabelRole, self.comboBox)
        self.comboBox_2 = QtGui.QComboBox(Form)
        self.comboBox_2.setObjectName("comboBox_2")
        self.comboBox_2.addItem("")
        self.comboBox_2.addItem("")
        self.comboBox_2.addItem("")
        self.formLayout.setWidget(10, QtGui.QFormLayout.LabelRole, self.comboBox_2)
        self.lineEdit = QtGui.QLineEdit(Form)
        self.lineEdit.setObjectName("lineEdit")
        self.formLayout.setWidget(11, QtGui.QFormLayout.SpanningRole, self.lineEdit)

        self.retranslateUi(Form)
        QtCore.QMetaObject.connectSlotsByName(Form)

    def retranslateUi(self, Form):
        Form.setWindowTitle(QtGui.QApplication.translate("Form", "Form", None, QtGui.QApplication.UnicodeUTF8))
        self.checkBox_2.setText(QtGui.QApplication.translate("Form", "Triggered Immediately (otherwise by Space, Enter ...)", None, QtGui.QApplication.UnicodeUTF8))
        self.checkBox.setText(QtGui.QApplication.translate("Form", "Autohotkey Command Mode", None, QtGui.QApplication.UnicodeUTF8))
        self.checkBox_6.setText(QtGui.QApplication.translate("Form", "SendPlay Mode", None, QtGui.QApplication.UnicodeUTF8))
        self.checkBox_4.setText(QtGui.QApplication.translate("Form", "replace inside words", None, QtGui.QApplication.UnicodeUTF8))
        self.checkBox_3.setText(QtGui.QApplication.translate("Form", "ignore the character which causes the replacement", None, QtGui.QApplication.UnicodeUTF8))
        self.checkBox_5.setText(QtGui.QApplication.translate("Form", "don\'t replace abbreviation but append the text", None, QtGui.QApplication.UnicodeUTF8))
        self.checkBox_7.setText(QtGui.QApplication.translate("Form", "output control-commands like {Enter}{Left} as plain text", None, QtGui.QApplication.UnicodeUTF8))
        self.checkBox_8.setText(QtGui.QApplication.translate("Form", "substitute !, +, ^, and # with Alt, Shift, Ctrl or Windows", None, QtGui.QApplication.UnicodeUTF8))
        self.comboBox.setItemText(0, QtGui.QApplication.translate("Form", "Ignore Case", None, QtGui.QApplication.UnicodeUTF8))
        self.comboBox.setItemText(1, QtGui.QApplication.translate("Form", "Case Sensitive", None, QtGui.QApplication.UnicodeUTF8))
        self.comboBox.setItemText(2, QtGui.QApplication.translate("Form", "Don\'t Conform To Typed Case", None, QtGui.QApplication.UnicodeUTF8))
        self.comboBox_2.setItemText(0, QtGui.QApplication.translate("Form", "Scope: Global", None, QtGui.QApplication.UnicodeUTF8))
        self.comboBox_2.setItemText(1, QtGui.QApplication.translate("Form", "Scope: Only In:", None, QtGui.QApplication.UnicodeUTF8))
        self.comboBox_2.setItemText(2, QtGui.QApplication.translate("Form", "Scope: Not In:", None, QtGui.QApplication.UnicodeUTF8))

