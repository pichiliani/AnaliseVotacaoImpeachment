import csv
import numpy as np

import pandas as pd
from sklearn import tree
from numpy import genfromtxt

# from matplotlib.mlab import PCA



#features_nome = ["c1","c2"]
#features = [[140,1], [130,1], [150,0], [170,0]]


########### FEATURES
#features_nome = ["c1","c2","c3","c4","c5","c6","c7","c8","c9","c10"]
#features_nome = genfromtxt('E:\Meus Documentos\Blog\BETA_AnaliseDiscursos\ArvoreDecisao\e_nomes.txt', delimiter=',')
#print(features_nome)


with open('E:\Meus Documentos\Blog\BETA_AnaliseDiscursos\ArvoreDecisao\e_nomes.txt', 'r') as f:
    reader = csv.reader(f)
    features_nome = list(reader)

print(features_nome[0])


features =pd.read_csv('E:\Meus Documentos\Blog\BETA_AnaliseDiscursos\ArvoreDecisao\e_todos.txt', sep=',',header=None)
print(features.values)

# tentativa de rodar o PCA...
# results = PCA(features)
# print(results.fracs)

########### LABELS

labels_nome = ["Contra","A favor"]
#nota: um resultado (0 ou 1) por linha
labels = genfromtxt('E:\Meus Documentos\Blog\BETA_AnaliseDiscursos\ArvoreDecisao\labels.txt', delimiter=',')
labels = np.asarray(labels, dtype = 'int')

print(labels)
#print(len(labels))


clf = tree.DecisionTreeClassifier()
clf = clf.fit(features, labels)

#print(clf.predict([[160,0]]))


#viz code
from sklearn.externals.six import StringIO
import pydotplus

dot_data = StringIO()

tree.export_graphviz(clf,
                      out_file=dot_data,
                      feature_names=features_nome[0],
                     class_names=labels_nome,
                      filled=True, rounded=True,
                      impurity=False)

graph = pydotplus.graph_from_dot_data(dot_data.getvalue())
graph.write_pdf("votacao.pdf")







#df =pd.read_csv('E:\Meus Documentos\Blog\BETA_AnaliseDiscursos\ArvoreDecisao\labels.txt', sep=',',header=None)
#print(df.values)



#with open('E:\Meus Documentos\Blog\BETA_AnaliseDiscursos\ArvoreDecisao\labels.txt','r') as dest_f:
#    data_iter = csv.reader(dest_f,
#                           delimiter = ',',
#                           quotechar = '"')
#    data = [data for data in data_iter]
#data_array = np.asarray(data, dtype = 'int')
#print(data)

