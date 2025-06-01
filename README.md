# Istio-Hand-On 1기 

## 개요
![image.png](https://841lgfvhej.execute-api.ap-northeast-2.amazonaws.com/default/image?url=https://gist.githubusercontent.com/Zerotay/5af027e2ed761430cacb2b75e5d18a3b/raw/image.png)

**클라우드넷 팀의 Istio Hands-on 1기 스터디**를 진행하며 진행한 내용들에 대한 파일을 정리해둔 레포지토리다.  
자세히 정리된 글은 [블로그](https://zerotay-blog.vercel.app/6.PUBLISHED/Istio%201%EA%B8%B0%20-%20Istio%20Hands-on/Istio%201%EA%B8%B0%20-%20Istio%20Hands-on/)에 담겨져 있으니 참고한다.  
체계적으로 정리하지는 못 했으나, 모든 코드를 작성하던 글에 정리할 수 없다고 판단하여 별도의 레포지토리를 두고 참조할 수 있도록 공개한다.  
특히 7주차, 8주차에 진행된 내용은 이 레포의 코드를 적극적으로 활용하는 것을 추천한다.  
## 디렉토리 간단 구조

딱히 구조랄 건 없지만, 각 서브 디렉에 공통되게 적용한 방식이 있어 미리 적어둔다.  
기본적으로 주차 별로 디렉토리를 나눈다.  
이때 각 실습에 사용되는 참고 파일들을 명확하게 디렉토리에 복사해서 넣어두었다.  
그러한 참고 파일은 사실 현 root 디렉의 `istio-v`, `book-source-code-master` 등에 담겨 있는 파일들을 그대로 복사한 것이다.  
가급적 디렉토리를 옮겨다니지 않도록, 그리고 버전 상의 문제가 생겨서 파일을 수정해야 할 때 의존성이 발생하지 않도록 복사해서 넣는 방식을 택했다.  


8주차의 경우 테라폼 디렉토리가 추가적으로 존재한다.  
해당 실습 내용 상 로컬에서 진행하지 않기 때문에 테라폼으로 환경 구축을 한 뒤에 실습할 수 있다.  
간단하게 terraform init && terraform apply -approve를 통해 실행할 수 있다.  
이때 aws creds 정보가 이미 로컬에 저장돼있어야 하니 유의한다.  
(~/.aws 디렉토리를 필요로 한다.)